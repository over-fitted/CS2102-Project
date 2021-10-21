/* # TRIGGERS & TRIGGER FUNCTIONS # */

/* ## Enforcing data integrity ## */
/* ## Note: All triggers here are initially deferred. ## */

-- ### All Employees must have at least one contact ###

-- #### Enforcing at insertion into Employees #### 
CREATE OR REPLACE FUNCTION _tf_employeeHasContact_insertEmployee()
RETURNS TRIGGER AS $$
DECLARE 
    number INTEGER := 0;
BEGIN 
    SELECT COUNT(*) INTO number
    FROM Contact c
    WHERE NEW.eid = c.eid;
    IF (number = 0) THEN 
        RAISE EXCEPTION 'Employee has no contact, insert blocked';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER _t_employeeHasContact_insertEmployee
AFTER INSERT ON Employees
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION _tf_employeeHasContact_insertEmployee();

-- #### Enforcing at removal from Contact
CREATE OR REPLACE FUNCTION _tf_employeeHasContact_removeContact()
RETURNS TRIGGER AS $$
DECLARE 
    number INTEGER := 0;
BEGIN 
    SELECT COUNT(*) INTO number
    FROM Contact c
    WHERE OLD.eid = c.eid
        AND OLD.phone != c.phone;
    IF (number = 0) THEN 
        RAISE NOTICE 'Employee has no contact';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER _t_employeeHasContact_removeContact
BEFORE DELETE ON Contact
FOR EACH ROW EXECUTE FUNCTION _tf_employeeHasContact_removeContact();


-- ### All Bookings must have at least one participant, which is the booker ###
CREATE OR REPLACE FUNCTION _tf_bookingInsertBooker()
RETURNS TRIGGER AS $$
BEGIN 
    INSERT INTO Participates 
    VALUES (
        NEW.booker_id,
        NEW.room,
        NEW.floor,
        NEW.date,
        NEW.time
    );
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER _t_bookingInsertBooker
AFTER INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION _tf_bookingInsertBooker();

-- ### A booking cannot have more participants than the stated capacity ###
CREATE OR REPLACE FUNCTION _tf_bookingWithinCapacity()
RETURNS TRIGGER AS $$
DECLARE
    currentCapacity INTEGER;
    capacity INTEGER;
BEGIN 
    SELECT COUNT(*) INTO currentCapacity
    FROM Participates p 
    GROUP BY p.room, p.floor, p.date, p.time;

    SELECT m.capacity INTO capacity
    FROM Meeting_Rooms;

    IF (currentCapacity = capacity) THEN
        RAISE NOTICE 'Meeting booking is full!';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER _t_bookingWithinCapacity
BEFORE INSERT ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_bookingWithinCapacity();

-- ### A Booking which is not immedietely approved by manager is removed
CREATE OR REPLACE FUNCTION _tf_bookingNotApproved() 
RETURNS TRIGGER AS $$
BEGIN
    -- ### Checking if manager has approved
    IF (NEW.approver_id IS NULL) THEN
        RAISE EXCEPTION 'Booking is not approved by manager, Booking deleted';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER _t_bookingNotApproved
AFTER INSERT ON Bookings
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION _tf_bookingNotApproved();

CREATE OR REPLACE FUNCTION _tf_fever_event()
RETURNS TRIGGER AS $$
DECLARE
    tempEmployee INTEGER;
BEGIN
    IF (NEW.temperature > 37.5) THEN
        RAISE NOTICE 'Employee % has fever', NEW.eid;
        -- ### Delete all booking by this employee
        DELETE FROM Bookings b
            WHERE b.booker_id = NEW.eid
                AND (b.date > NEW.date OR (b.date = NEW.date AND b.time > NEW.time));
        -- ### Remove employee from all future meetings
        DELETE FROM Participates p
            WHERE p.eid = NEW.eid
                AND (p.date > NEW.date OR (p.date = NEW.date AND p.time > NEW.time));
        
        FOR tempEmployee IN SELECT * FROM _f_contact_tracing(NEW.eid)
        LOOP
            -- ### Delete all made by close contact employee in the next 7 days
            DELETE FROM Bookings b
            WHERE b.booker_id = tempEmployee
                AND ((b.date - NEW.date > 0 AND b.date - NEW,date <= 7) OR (b.date = NEW.date AND b.time > NEW.time));
        -- ### Remove close contact employee from all future meetings in the next 7 days
            DELETE FROM Participates p
            WHERE p.eid = tempEmployee
                AND ((p.date - NEW.date > 0 AND p.date - NEW.date <= 7)  OR (p.date = NEW.date AND p.time > NEW.time));
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER _t_fever_event
AFTER INSERT ON HealthDeclaration
FOR EACH STATEMENT EXECUTE FUNCTION _tf_fever_event();

/* FUNCTIONS */

CREATE OR REPLACE FUNCTION _f_contact_tracing
    (IN _i_employeeId INTEGER)
RETURNS TABLE(_o_closeContactEmployeeId INTEGER) AS $$
DECLARE
    _v_dateDeclare DATE;
    _v_timeDeclare TIME;
    _v_meeting RECORD;
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
        CREATE TEMP TABLE attendedMeeting(room INTEGER, floor INTEGER, date DATE, time TIME);
        CREATE TEMP TABLE closeContactId (empId INTEGER);

        -- ### Find all the meetings the person with fever attended
        INSERT INTO attendedMeeting
            SELECT p.room, p.floor, p.date, p.time
            FROM Participates p
            WHERE p.eid = _i_employeeId
                AND ((_v_dateDeclare - p.date > 0 AND _v_dateDeclare - p.date <= 3) OR (_v_dateDeclare = p.date AND _v_timeDeclare > p.time));
        
        -- ### Add in everyone who attending the meeting the person with fever attended
        FOR _v_meeting IN (
            SELECT room, floor, date, time
            FROM attendedMeeting
        )
        LOOP
            SELECT * FROM closeContactId
            UNION
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

CREATE OR REPLACE FUNCTION _f_non_compliance
    (IN _i_startDate DATE, IN _i_endDate DATE)
RETURNS TABLE(employeeId INTEGER, numDays INTEGER) AS $$
BEGIN
    -- ### Get rid of multiple declaration per day
    CREATE TEMP TABLE distinctDeclaration(date DATE, time TIME, eid INTEGER, temperature INTEGER);
    INSERT INTO distinctDeclaration
        SELECT DISTINCT h.date, h.eid
        FROM HealthDeclaration h;

    -- ### Select employeeid's whose declaration are within the date range and have not made atleast one declaration a day
    RETURN QUERY SELECT h.eid AS employeeId, ((_i_endDate - _i_startDate) - COUNT(h.eid)) AS numDays
                    FROM distinctDeclaration h
                    WHERE (h.date >= _i_startDate AND h.date <= _i_endDate)
                    GROUP BY h.eid
                    HAVING COUNT(h.eid) < (_i_endDate - _i_startDate);
END;
$$ LANGUAGE plpgsql;

/* PROCEDURES */

CREATE OR REPLACE PROCEDURE _p_approve_meeting
    (IN _i_floorNumber INTEGER, IN _i_roomNumber INTEGER, IN _i_inputDate DATE, IN _i_startHour TIMESTAMP, IN _i_endHour TIMESTAMP, IN _i_managerEid INTEGER)
AS $$

<<BeginLabel>>
DECLARE
    _v_tempStartHour INTEGER := _i_startHour;
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
        WHERE e.eid = _i_managerEid;

        SELECT b.booker_id INTO _v_employeeId
        FROM Bookings b
        WHERE b.floor = _i_floorNumber
                AND b.room = _i_roomNumber
                AND b.date = _i_inputDate
                AND startHour = _i_startHour;
        
        SELECT b.did INTO _v_employeeDept
        FROM Employees e
        WHERE e.eid = _v_employeeId;

        -- ### Approve all bookings until employeeDept != mangerDept
        IF (_v_managerDept = _v_employeeDept) THEN
            UPDATE Bookings b
                SET approver_id = _i_managerEid
                WHERE 
                    b.floor = floorNumber
                    AND b.room = roomNumber
                    AND b.date = inputDate
                    AND startHour = _v_tempStartHour;
            
            _v_tempStartHour = _v_tempStartHour + 1;
        ELSE
            RAISE EXCEPTION 'Employee Department and Manger Department are different';
            EXIT MainLoop;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE _p_declare_health
    (IN _i_eid INTEGER, IN _i_date DATE, IN _i_temperature INTEGER, IN _i_time TIME)
AS $$
BEGIN
    INSERT INTO HealthDeclaration
        VALUES (
        date,
        _i_time,
        _i_eid,
        _i_temperature
    ); 
END;
$$ LANGUAGE plpgsql;