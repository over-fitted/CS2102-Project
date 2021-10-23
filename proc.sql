/* # TRIGGERS & TRIGGER FUNCTIONS # */

/* ## Enforcing data integrity ## */
/* ## Note: All triggers here are initially deferred. ## */

-- ### A Booking which is not immedietely approved by manager is removed
CREATE OR REPLACE FUNCTION _tf_bookingNotApproved() 
RETURNS TRIGGER AS $$

DECLARE
    apporver INTEGER;

BEGIN
    -- ### Checking if manager has approved
    SELECT b.approver_id INTO apporver
    FROM Bookings b
    WHERE b.floor = NEW.floor
        AND b.room = NEW.room
        AND b.date = NEW.date
        AND b.time = NEW.time
        AND b.booker_id = NEW.booker_id;
    
    IF (apporver IS NULL) THEN
        RAISE EXCEPTION 'Booking is not approved by manager, Booking deleted';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ### Trigger which calls function to removed bookings which are not approved
CREATE CONSTRAINT TRIGGER _t_bookingNotApproved
AFTER INSERT ON Bookings
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION _tf_bookingNotApproved();

-- ### Fever_event trigger function, handles removal of employee's and close contact's previous booking and meetings
CREATE OR REPLACE FUNCTION _tf_fever_event()
RETURNS TRIGGER AS $$
DECLARE
    tempEmployee INTEGER;
    items RECORD;
BEGIN
    IF (NEW.temperature > 37.5) THEN
        RAISE NOTICE 'TRIGGER: Employee % has fever', NEW.eid;

        FOR tempEmployee IN (SELECT * FROM _f_contact_tracing(NEW.eid))
        LOOP
            RAISE NOTICE'Close contact employees : %', tempEmployee;
            -- ### Delete booking all made by close contact employee in the next 7 days
            DELETE FROM Bookings b
            WHERE b.booker_id = tempEmployee
                AND ((b.date - NEW.date > 0 AND b.date - NEW.date <= 7) OR (b.date = NEW.date AND b.time > NEW.time));
            -- ### Remove close contact employee from all future meetings in the next 7 days
            DELETE FROM Participates p
            WHERE p.eid = tempEmployee
                AND ((p.date - NEW.date > 0 AND p.date - NEW.date <= 7)  OR (p.date = NEW.date AND p.time > NEW.time));
        END LOOP;

        -- ### Delete all booking by this employee
        DELETE FROM Bookings b
            WHERE b.booker_id = NEW.eid
                AND (b.date > NEW.date OR (b.date = NEW.date AND b.time > NEW.time));
        -- ### Remove employee from all future meetings
        DELETE FROM Participates p
            WHERE p.eid = NEW.eid
                AND (p.date > NEW.date OR (p.date = NEW.date AND p.time > NEW.time));
        

    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ### Trigger to check if any employee has fever
CREATE OR REPLACE TRIGGER _t_fever_event
AFTER INSERT ON HealthDeclaration
FOR EACH ROW EXECUTE FUNCTION _tf_fever_event();


/* FUNCTIONS */

-- ### Returns employees who were in close contact with an employee if they have fever
CREATE OR REPLACE FUNCTION _f_contact_tracing
    (IN _i_employeeId INTEGER)
RETURNS TABLE(_o_closeContactEmployeeId INTEGER) AS $$
DECLARE
    _v_dateDeclare DATE;
    _v_timeDeclare TIME;
    _v_meeting RECORD;
    print_test INTEGER;
BEGIN
    -- ### Find latest date of declaration if temperature is over 37.5
    SELECT h.date INTO _v_dateDeclare
        FROM HealthDeclaration h
        WHERE h.temperature > 37.5
            AND h.eid = _i_employeeId
        ORDER BY h.date DESC
        LIMIT 1;
    

    -- ### Find latest time of declaration if temperature is over 37.5
    SELECT h.time INTO _v_timeDeclare
        FROM HealthDeclaration h
        WHERE h.temperature > 37.5
            AND h.eid = _i_employeeId
        ORDER BY h.date DESC, h.time DESC
        LIMIT 1;

    -- ### No fever
    IF (_v_dateDeclare IS NULL) THEN
        RETURN;
    ELSE
        DROP TABLE IF EXISTS attendedMeeting;
        DROP TABLE IF EXISTS closeContactId;

        CREATE TEMP TABLE attendedMeeting(room INTEGER, floor INTEGER, date DATE, time TIME);
        CREATE TEMP TABLE closeContactId (empId INTEGER);

        -- ### Find all the meetings the person with fever attended
        INSERT INTO attendedMeeting
            SELECT p.room, p.floor, p.date, p.time
            FROM Participates p
            WHERE p.eid = _i_employeeId
                AND ((_v_dateDeclare - p.date > 0 AND _v_dateDeclare - p.date <= 3) OR (p.date = _v_dateDeclare AND _v_timeDeclare - p.time >= '0 seconds'::interval));
        
        -- ### Add in everyone who had attended a the meeting with person with fever
        FOR _v_meeting IN (
            SELECT room, floor, date, time
            FROM attendedMeeting
        )
        LOOP
            INSERT INTO closeContactId
            SELECT p.eid
            FROM Participates p
            WHERE p.room = _v_meeting.room
                AND p.floor = _v_meeting.floor
                AND p.date = _v_meeting.date
                AND p.time = _v_meeting.time;
        END LOOP;
        RETURN QUERY SELECT * FROM closeContactId;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS _f_non_compliance(date,date);

-- ### Returns employee_id and number of times they default on declaring temperature
CREATE OR REPLACE FUNCTION _f_non_compliance
    (IN _i_startDate DATE, IN _i_endDate DATE)
RETURNS TABLE(employeeId INTEGER, numDays BIGINT) AS $$

DECLARE
    print_test INTEGER;

BEGIN
    -- ### Get rid of multiple declaration per day
    DROP TABLE IF EXISTS distinctDeclaration;
    CREATE TEMP TABLE distinctDeclaration(date DATE, eid INTEGER);
    
    INSERT INTO distinctDeclaration
        SELECT DISTINCT h.date, h.eid
        FROM HealthDeclaration h;

    -- ### Select employeeid's whose declaration are within the date range and have not made atleast one declaration a day
    RETURN QUERY SELECT e.eid AS employeeId, ((_i_endDate - _i_startDate) - COUNT(h.eid) + 1) AS numDays
                    FROM distinctDeclaration h RIGHT JOIN Employees e
                    ON h.eid = e.eid
                    WHERE ((h.date >= _i_startDate AND h.date <= _i_endDate) OR h.date IS NULL)
                    GROUP BY e.eid
                    HAVING COUNT(h.eid) <= (_i_endDate - _i_startDate);
END;
$$ LANGUAGE plpgsql;

/* PROCEDURES */

-- ### Approves a Booking if valid within a time frame provided
CREATE OR REPLACE PROCEDURE _p_approve_meeting
    (IN _i_roomNumber INTEGER, IN _i_floorNumber INTEGER, IN _i_inputDate DATE, IN _i_startHour TIME, IN _i_endHour TIME, IN _i_managerEid INTEGER)
AS $$

<<BeginLabel>>
DECLARE
    _v_tempStartHour TIME := _i_startHour;
    _v_employeeId INTEGER;
    _v_employeeDept INTEGER;
    _v_managerDept INTEGER;
BEGIN   
    -- ### Ensure input is correct
    IF (_i_startHour > _i_endHour) THEN
        EXIT BeginLabel;
    END IF;
    
    <<MainLoop>>
    LOOP
        -- ### All the bookings have been approved then exit
        EXIT WHEN _v_tempStartHour > _i_endHour;
        
        -- ### Checks whether employee's department is the same as the manager's department
        SELECT e.did INTO _v_managerDept
        FROM Employees e
        WHERE e.eid = _i_managerEid
            AND e.resigned_date IS NULL;

        SELECT b.booker_id INTO _v_employeeId
        FROM Bookings b
        WHERE b.floor = _i_floorNumber
                AND b.room = _i_roomNumber
                AND b.date = _i_inputDate
                AND b.time = _v_tempStartHour;

        SELECT e.did INTO _v_employeeDept
        FROM Employees e
        WHERE e.eid = _v_employeeId;

       
        -- ### If manger department is null he has resigned or doesnt exist
        IF (_v_managerDept IS NULL) THEN
            RAISE EXCEPTION 'Manager is Resigned';
        END IF;


        -- ### Approve all bookings until employeeDept != mangerDept
        IF (_v_managerDept = _v_employeeDept) THEN
            UPDATE Bookings b
                SET approver_id = _i_managerEid
                WHERE 
                    b.floor = _i_floorNumber
                    AND b.room = _i_roomNumber
                    AND b.date = _i_inputDate
                    AND b.time = _v_tempStartHour
                    AND b.approver_id IS NULL;
        ELSE
            RAISE NOTICE 'Employee Dept: %, Manger Dept: %',_v_employeeDept, _v_managerDept;
            RAISE EXCEPTION 'Employee Department and Manger Department are different';
            EXIT MainLoop;
        END IF;
        _v_tempStartHour := _v_tempStartHour + '1 hour'::interval;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ### Declare the health for an employee
CREATE OR REPLACE PROCEDURE _p_declare_health
    (IN _i_eid INTEGER, IN _i_date DATE, IN _i_temperature NUMERIC, IN _i_time TIME)
AS $$
BEGIN
    INSERT INTO HealthDeclaration
        VALUES (
        _i_date,
        _i_time,
        _i_eid,
        _i_temperature
    ); 
END;
$$ LANGUAGE plpgsql;