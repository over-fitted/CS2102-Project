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
CREATE OR REPLACE FUNCTION _tf_deleteBooking() 
RETURNS TRIGGER AS $$
BEGIN
    -- ### Checking if manager has approved
    IF ((SELECT b.approver.id FROM Bookings b WHERE b.booker_id = NEW.booker_id) IS NULL) THEN
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
FOR EACH ROW EXECUTE FUNCTION _tf_deleteBooking();

CREATE OR REPLACE FUNCTION _tf_contactTracing()
RETURNS TRIGGER AS $$
DECLARE
    tempEmployee INTEGER;
BEGIN
    IF (NEW.temperature > 37.5) THEN
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
FOR EACH STATEMENT EXECUTE FUNCTION _tf_contactTracing();

/* FUNCTIONS */

CREATE OR REPLACE FUNCTION _f_contact_tracing
    (IN employeeId INTEGER)
RETURNS TABLE(closeContactEmployeeId INTEGER) AS $$
DECLARE
    dateDeclare DATE;
    timeDeclare TIME;
    meeting record;
BEGIN
    -- ### Find latest date of declaration if temperature is over 37.5
    SELECT h.date INTO dateDeclare
        FROM HealthDeclaration h
        WHERE h.temperature > 37.5
            AND h.eid = employeeId
        ORDER BY h.date DESC
        LIMIT 1;
    
    -- ### Find latest time of declaration if temperature is over 37.5
    SELECT h.time INTO timeDeclare
        FROM HealthDeclaration h
        WHERE h.temperature > 37.5
            AND h.eid = employeeId
        ORDER BY h.date DESC, h.time DESC
        LIMIT 1;

    -- ### No fever
    IF (dateDeclare IS NULL) THEN
        RETURN;
    ELSE
        CREATE TEMP TABLE attendedMeeting(room INTEGER, floor INTEGER, date DATE, time TIME);
        CREATE TEMP TABLE closeContactId (empId INTEGER);

        -- ### Find all the meetings the person with fever attended
        INSERT INTO attendedMeeting
            SELECT p.room, p.floor, p.date, p.time
            FROM Participates p
            WHERE p.eid = employeeId
                AND ((dateDeclare - p.date > 0 AND dateDeclare - p.date <= 3) OR (dateDeclare = p.date AND timeDeclare > p.time));
        
        -- ### Add in everyone who attending the meeting the person with fever attended
        FOR meeting IN (
            SELECT room, floor, date, time
            FROM attendedMeeting
        )
        LOOP
            SELECT * FROM closeContactId
            UNION
            SELECT p.eid
            FROM Participates p
            WHERE p.room = meeting.room
                AND p.floor = meeting.floor
                AND p.date = meeting.date
                AND p.time = meeting.time;
        END LOOP;
        RETURN QUERY SELECT * FROM closeContactId;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _f_non_compliance
    (IN startDate DATE, IN endDate DATE)
RETURNS TABLE(employeeId INTEGER, numDays INTEGER) AS $$
BEGIN
    -- ### Get rid of multiple declaration per day
    CREATE TEMP TABLE distinctDeclaration(date DATE, time TIME, eid INTEGER, temperature INTEGER);
    INSERT INTO distinctDeclaration
        SELECT DISTINCT h.date, h.eid
        FROM HealthDeclaration h;

    -- ### Select employeeid's whose declaration are within the date range and have not made atleast one declaration a day
    RETURN QUERY SELECT h.eid AS employeeId, ((endDate - startDate) - COUNT(h.eid)) AS numDays
                    FROM distinctDeclaration h
                    WHERE (h.date >= startDate AND h.date <= endDate)
                    GROUP BY h.eid
                    HAVING COUNT(h.eid) < (endDate - startDate);
END;
$$ LANGUAGE plpgsql;

/* PROCEDURES */

CREATE OR REPLACE PROCEDURE _p_approve_meeting
    (IN floorNumber INTEGER, IN roomNumber INTEGER, IN inputDate DATE, IN startHour TIMESTAMP, IN endHour TIMESTAMP, IN managerEid INTEGER)
AS $$

<<BeginLabel>>
DECLARE
    tempStartHour INTEGER := startHour;
    employeeId INTEGER;
    employeeDept INTEGER;
    managerDept INTEGER;
BEGIN   
    -- ### Ensure input is correct
    IF (startHour > endHour) THEN
        EXIT BeginLabel;
    END IF;
    
    <<MainLoop>>
    LOOP
        -- ### All the bookings have been approved then exit
        EXIT WHEN tempStartHour > endHour;
        
        -- ### Checks whether employee's department is the same as the manager's department
        SELECT e.did INTO managerDept
        FROM Employees e
        WHERE e.eid = managerEid;

        SELECT b.booker_id INTO employeeId
        FROM Bookings b
        WHERE b.floor = floorNumber
                AND b.room = roomNumber
                AND b.date = inputDate
                AND startHour = startHour;
        
        SELECT b.did INTO employeeDept
        FROM Employees e
        WHERE e.eid = employeeId;

        -- ### Approve all bookings until employeeDept != mangerDept
        IF (managerDept = employeeDeptId) THEN
            UPDATE Bookings b
                SET approver_id = managerEid
                WHERE 
                    b.floor = floorNumber
                    AND b.room = roomNumber
                    AND b.date = inputDate
                    AND startHour = tempStartHour;
            
            tempStartHour = tempStartHour + 1;
        ELSE
            RAISE EXCEPTION 'Employee Department and Manger Department are different';
            EXIT MainLoop;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE _p_declare_health
    (IN eid INTEGER, IN date DATE, IN temperature INTEGER, IN inTime TIME)
AS $$
BEGIN
    INSERT INTO HealthDeclaration
        VALUES (
        date,
        inTime,
        eid,
        temperature
    ); 
END;
$$ LANGUAGE plpgsql;