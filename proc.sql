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

/* FUNCTIONS */

/*
CREATE OR REPLACE FUNCTION _f_contact_tracing
    (IN employeeId)
RETURNS TABLE(closeContactEmployeeId INTEGER) AS $$
DECLARE
    curs CURSOR FOR (
        SELECT p.room, p.floor, p.date, p.time 
        FROM Participates p 
        WHERE p.eid);
    r RECORD;
BEGIN
    OPEN curs;
    CREATE TEMP TABLE closeContactId (empId INTEGER);

    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;
        closeContactId UNION (
            SELECT p.eid 
            FROM Participates p 
            WHERE r.room = p.room
                AND r.floor = p.floor
                AND r.date = p.date
                AND r.time = p.time)
    END LOOP
    CLOSE curs;
END;
$$ LANGUAGE plpgsql
*/

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
    (IN employeeId INTEGER, IN inDate DATE, IN temperature INTEGER)
AS $$
BEGIN
    INSERT INTO HealthDeclaration
        VALUES (
        inDate,
        employeeId,
        temperature
    ); 
END;
$$ LANGUAGE plpgsql;