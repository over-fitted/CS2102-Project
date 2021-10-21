/* # TRIGGERS & TRIGGER FUNCTIONS # */



/* ## Enforcing data integrity ## */
/* Note: All triggers here are initially deferred. ## */

-- ### All Bookings must have at least one participant, which is the booker ###
CREATE OR REPLACE FUNCTION _tf_bookingInsertBooker()
RETURNS TRIGGER AS $$
BEGIN 
    RAISE NOTICE 'TRIGGER: Inserting booker % into booking he made in room %, floor %, date %, time %', 
        NEW.booker, NEW.room, NEW.floor, NEW.date, NEW.time;
    -- see if new row is already in participates
    IF NOT EXISTS (
        SELECT 1
        FROM Participates p
        WHERE p.booker_id = NEW.booker
            AND p.room = NEW.room
            AND p.floor = NEW.floor
            AND p.date = NEW.date 
            AND p.time = NEW.time
    ) THEN
        INSERT INTO Participates 
        VALUES (
            NEW.booker_id,
            NEW.room,
            NEW.floor,
            NEW.date,
            NEW.time
        );
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER _t_bookingInsertBooker
AFTER INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION _tf_bookingInsertBooker();

-- ### A booking cannot have more participants than the stated capacity ###
CREATE OR REPLACE FUNCTION _tf_bookingWithinCapacity()
RETURNS TRIGGER AS $$
DECLARE
    _v_currentCapacity INTEGER;
    _v_capacity INTEGER;
BEGIN 
    RAISE NOTICE 'TRIGGER: Checking if booking made by % in room %, floor %, date %, time % is within capacity', 
        NEW.booker, NEW.room, NEW.floor, NEW.date, NEW.time;
    SELECT COUNT(*) INTO _v_currentCapacity
    FROM Participates p 
    GROUP BY p.room, p.floor, p.date, p.time;

    SELECT m.capacity INTO _v_capacity
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
    RAISE NOTICE 'TRIGGER: Checking and removing rows that violate new capacity for room % floor %', NEW.room, NEW.floor;
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



/* ## Application function triggers ## */
-- ### Resigning of an employee should trigger a removal of all future bookings he has made ###
CREATE OR REPLACE FUNCTION _tf_removeResignedBookings()
RETURNS TRIGGER AS $$
DECLARE 
    curs CURSOR FOR (
        SELECT b.room, b.floor, b.date, b.time
        FROM Bookings b
        WHERE b.booker_id = NEW.eid
            AND NEW.resigned_date IS NOT NULL -- resigned
            AND b.date > NEW.resigned_date
    );
    r RECORD;
BEGIN 
    RAISE NOTICE 'TRIGGER: Employee % resigned, checking and removing future bookings he made after %', NEW.eid, NEW.resigned_date;   
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


-- ### Removing a department ###
CREATE OR REPLACE PROCEDURE remove_department
    (IN _i_did INTEGER)
AS $$
BEGIN
    /* 
    Meeting room's location dependency on department is maintained by it's foreign key 
    No need to enforce with triggers, will throw exception
    */
    DELETE FROM Departments d
    WHERE d.did = _i_did;
END;
$$ LANGUAGE plpgsql;

-- ### Adding a room ###
CREATE OR REPLACE PROCEDURE add_room
    (IN floor INTEGER, IN room INTEGER, IN rname VARCHAR(50), 
    IN did INTEGER, IN capacity INTEGER)
AS $$
BEGIN
    INSERT INTO MeetingRooms
    VALUES(floor, room, rname, did, capacity);
END;
$$ LANGUAGE plpgsql;

-- ### Changing meeting room capacity ###
CREATE OR REPLACE PROCEDURE change_capacity
    (IN _i_floor INTEGER, IN _i_room INTEGER, IN _i_capacity INTEGER, IN _i_date DATE, IN _i_eid INTEGER)
AS $$
BEGIN
    -- check if employer changing capacity is a mananger of the department


    UPDATE MeetingRooms 
    SET capacity = _i_capacity
    WHERE floor = _i_floor AND room = _i_room;
END;
$$ LANGUAGE plpgsql;


-- ### Add employee ###
CREATE OR REPLACE PROCEDURE add_employee
    (IN _i_ename VARCHAR(50), IN _i_home_number VARCHAR(50),
        IN _i_mobile_number VARCHAR(50), IN _i_office_number VARCHAR(50), 
        IN _i_etype VARCHAR(7), IN _i_did INTEGER)
AS $$
DECLARE
    _v_eid INTEGER;
    _v_email VARCHAR(50);
BEGIN
    SELECT COUNT(DISTINCT eid) + 1 INTO _v_eid
    FROM Employees;

    SELECT CONCAT(CAST(eid AS VARCHAR(50)), '@office.com') INTO _v_email;

    INSERT INTO Employees
    VALUES(_v_eid, _i_ename, _v_email, _i_etype, _i_did, 
        NULL, _i_home_number, _i_mobile_number, _i_office_number);

    INSERT INTO Contact
    VALUES(_v_eid, _i_phone);
END;
$$ LANGUAGE plpgsql;


-- ### Remove employee (make resign) ###
CREATE OR REPLACE PROCEDURE remove_employee
    (IN _i_eid INTEGER, IN _i_date DATE)
AS $$
BEGIN
    UPDATE Employees
    SET resigned_date = _i_date
    WHERE eid = _i_eid;
END;
$$ LANGUAGE plpgsql;