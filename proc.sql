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
        RAISE NOTICE 'Employee has no contact, insert blocked';
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
    FROM MeetingRooms;

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

/* ## Application function triggers ## */
-- ### Changing room capacity should trigger a removal of all violating future bookings
CREATE OR REPLACE FUNCTION _tf_removeViolatingBookings()
RETURNS TRIGGER AS $$
DECLARE 
    curs CURSOR FOR (
        SELECT b.room, b.floor, b.date, b.time, COUNT(*) as numParticipants
        FROM Bookings b, Participates p
        WHERE b.room = p.room
            AND b.date = p.date
            AND b.floor = p.floor
            AND b.time = p.time
            AND b.room = NEW.room
            AND b.floor = NEW.floor
        GROUP BY (b.room, b.floor, b.date, b.time)
    );
    r RECORD;
BEGIN 
    OPEN curs;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;

        IF (r.numParticipants > (
            SELECT capacity
            FROM MeetingRooms m
            WHERE r.room = m.room
                AND r.floor = m.floor
                AND r.date > m.date
        )) THEN 
            DELETE FROM Bookings b
            WHERE b.room = r.room
                AND b.floor = r.floor
                AND b.date = r.date
                AND b.time = r.time;
        END IF;

    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER _t_removeViolatingBookings
AFTER UPDATE ON MeetingRooms
FOR EACH ROW EXECUTE FUNCTION _tf_removeViolatingBookings();

-- ### Resignation of employee should remove all future bookings
CREATE OR REPLACE TRIGGER _t_bookingWithinCapacity
BEFORE INSERT ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_bookingWithinCapacity();

/* ## Application function triggers ## */
-- ### Changing room capacity should trigger a removal of all violating future bookings
CREATE OR REPLACE FUNCTION _tf_removeResignedBookings()
RETURNS TRIGGER AS $$
DECLARE 
    curs CURSOR FOR (
        SELECT b.room, b.floor, b.date, b.time
        FROM Bookings b
        WHERE b.booker_id = OLD.eid
            AND OLD.date IS NOT NULL -- resigned
            AND b.date > OLD.date
    );
    r RECORD;
BEGIN 
    OPEN curs;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;

        DELETE FROM Bookings b
        WHERE b.room = r.room
            AND b.floor = r.floor
            AND b.date = r.date
            AND b.time = r.time;

    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER _t_removeResignedBookings
AFTER UPDATE ON Employees
FOR EACH ROW EXECUTE FUNCTION _tf_removeResignedBookings();



/* # FUNCTIONS # */

-- ## Core ##

-- ### Search for available rooms



/* # PROCEDURES # */
-- ## Basic ## 
CREATE OR REPLACE FUNCTION search_room
    (IN booking_capacity INTEGER, 
        IN date DATE, 
        IN time_start TIME,
        IN time_end TIME,
        OUT floor INTEGER,
        OUT room INTEGER,
        OUT did INTEGER,
        OUT capacity INTEGER)
RETURNS SETOF RECORD AS $$
BEGIN
    /*
    Idea: find all meeting rooms not in 
    bookings at the given time that have a valid
    capacity.
    */
    WITH possibleMeetingRooms AS (
        SELECT DISTINCT m.floor, m.room, m.did, m.capacity
        FROM MeetingRooms m
        WHERE m.capacity <= booking_capacity
    ), bookedRooms AS (
        SELECT DISTINCT b.floor, b.room, mb.did, mb.capacity
        FROM Bookings b, MeetingRooms mb
        WHERE b.time >= time_start
            AND DATEADD(HOUR, 1, b.time) < time_end
            AND b.room = mb.room
            AND b.floor = mb.floor
    ), target AS (
        SELECT * FROM possibleMeetingRooms
        EXCEPT
        SELECT * FROM bookedRooms
    )
    SELECT floor, room, did, capacity
    FROM target;
END;
$$ LANGUAGE plpgsql;

-- ### Adding a department ###
CREATE OR REPLACE PROCEDURE add_department
    (IN did INTEGER, IN dname VARCHAR(50))
AS $$
BEGIN
    INSERT INTO Departments 
    VALUES(did, dname);
END;
$$ LANGUAGE plpgsql;

-- ### Adding a department ###
CREATE OR REPLACE PROCEDURE remove_department
    (IN did INTEGER)
AS $$
BEGIN
    /* 
    Meeting room's location dependency on department is maintained by it's foreign key 
    No need to enforce with triggers, will throw exception
    */
    DELETE FROM Departments d
    WHERE d.did = did;
END;
$$ LANGUAGE plpgsql;

-- ### Adding a room ###
CREATE OR REPLACE PROCEDURE add_room
    (IN floor INTEGER, IN room INTEGER, IN rname VARCHAR(50), 
    IN did INTEGER, IN capacity INTEGER)
AS $$
DECLARE
    defaultaDate DATE := 0;
BEGIN
    INSERT INTO MeetingRooms
    VALUES(floor, room, rname, did, capacity);
END;
$$ LANGUAGE plpgsql;

-- ### Changing meeting room capacity ###
CREATE OR REPLACE PROCEDURE change_capacity
    (IN floor INTEGER, IN room INTEGER, IN capacity INTEGER, IN date DATE)
AS $$
BEGIN
    UPDATE MeetingRooms m
    SET m.capacity = capacity
    WHERE m.floor = floor AND m.room = room;
END;
$$ LANGUAGE plpgsql;


-- ### Add employee ###
CREATE OR REPLACE PROCEDURE add_employee
    (IN ename VARCHAR(50), IN phone VARCHAR(50), IN etype VARCHAR(7), IN did INTEGER)
AS $$
DECLARE
    eid INTEGER;
    email VARCHAR(50);
BEGIN
    SELECT COUNT(DISTINCT eid) + 1 INTO eid
    FROM Employees;

    SELECT CONCAT(CAST(eid AS VARCHAR(50)), "@office.com") INTO email;

    INSERT INTO Employees
    VALUES(eid, ename, email, etype, did);

    INSERT INTO Contact
    VALUES(eid, phone);
END;
$$ LANGUAGE plpgsql;


-- ### Remove employee (make resign) ###
CREATE OR REPLACE PROCEDURE remove_employee
    (IN eid INTEGER, IN date DATE)
AS $$
DECLARE
    eid INTEGER;
    email VARCHAR(50);
BEGIN
    UPDATE Employees e
    SET e.resigned_date = date
    WHERE e.eid = eid;
END;
$$ LANGUAGE plpgsql;