/*
This SQL file contains all the processes of the database: Triggers, Functions & Procedures
PostgreSQL Version: 14.0 (Released 30th September 2021)
Authors: @tanyjnaaman, @AryanSarswat, @arijitnoobstar, @over-fitted
*/

/* ===== TRIGGERS ===== */

/*
@tanyjnaaman
This trigger ensures that if an employee resigns, his future bookings are removed.
It also ensures that an update to the resigned field is done exactly once.
*/
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
    RAISE NOTICE 'TRIGGER: Checking employee % has resigned exactly once', NEW.eid;
    IF ((OLD.resigned_date IS NOT NULL) AND (NEW.resigned_date IS NOT NULL)) THEN
      RAISE EXCEPTION 'EXCEPTION: Illegal attempt to update resignation date!';
    END IF;
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
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER _t_removeResignedBookings
AFTER UPDATE ON Employees
FOR EACH ROW EXECUTE FUNCTION _tf_removeResignedBookings();

/*
@tanyjnaaman
This trigger ensures that upon a room capacity change, all future bookings that violate it
are removed.
*/
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
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER _t_removeViolatingBookings
AFTER UPDATE ON MeetingRooms
FOR EACH ROW EXECUTE FUNCTION _tf_removeViolatingBookings();


/*
@AryanSarswat
This trigger ensures that a booking that is not approved 
in the same transaction (i.e. immediately) is deleted.
*/
CREATE OR REPLACE FUNCTION _tf_bookingNotApproved() 
RETURNS TRIGGER AS $$

DECLARE
    _v_approver INTEGER;
BEGIN
    -- ### Checking if manager has approved
    SELECT b.approver_id INTO _v_approver
    FROM Bookings b
    WHERE b.floor = NEW.floor
        AND b.room = NEW.room
        AND b.date = NEW.date
        AND b.time = NEW.time
        AND b.booker_id = NEW.booker_id;
    
    IF (_v_approver IS NULL) THEN
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

/*
@AryanSarswat
In the event an employee has a fever, he is removed from all future bookings, his bookings
are cancelled, and all close contacts are removed from meetings in the next 7 days, including
those they booked (i.e. their bookings that lie in the next 7 days are also deleted.

This trigger enforces these changes.
*/
CREATE OR REPLACE FUNCTION _tf_fever_event()
RETURNS TRIGGER AS $$
DECLARE
    _v_tempEmployee INTEGER;
BEGIN
    IF (NEW.temperature > 37.5) THEN
        RAISE NOTICE 'TRIGGER: Employee % has fever', NEW.eid;

        FOR _v_tempEmployee IN (SELECT * FROM _f_contact_tracing(NEW.eid))
        LOOP
            RAISE NOTICE'Close contact employees : %', _v_tempEmployee;
            -- ### Delete booking all made by close contact employee in the next 7 days
            DELETE FROM Bookings b
            WHERE b.booker_id = _v_tempEmployee
                AND ((b.date - NEW.date > 0 AND b.date - NEW.date <= 7) OR (b.date = NEW.date AND b.time > NEW.time));
            -- ### Remove close contact employee from all future meetings in the next 7 days
            DELETE FROM Participates p
            WHERE p.eid = _v_tempEmployee
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

CREATE TRIGGER _t_fever_event
AFTER INSERT ON HealthDeclaration
FOR EACH ROW EXECUTE FUNCTION _tf_fever_event();

/*
@tanyjnaaman
This trigger ensures that a person who booked a meeting will participate in it.
*/
-- CREATE OR REPLACE FUNCTION _tf_bookingInsertBooker()
-- RETURNS TRIGGER AS $$
-- BEGIN 
--     RAISE NOTICE 'TRIGGER: Inserting booker % into booking he made in room %, floor %, date %, time %', 
--         NEW.booker_id, NEW.room, NEW.floor, NEW.date, NEW.time;
--     -- see if new row is already in participates
--     IF NOT EXISTS (
--         SELECT 1
--         FROM Participates p
--         WHERE p.eid = NEW.booker_id
--             AND p.room = NEW.room
--             AND p.floor = NEW.floor
--             AND p.date = NEW.date 
--             AND p.time = NEW.time
--     ) THEN
--         INSERT INTO Participates 
--         VALUES (
--             NEW.booker_id,
--             NEW.room,
--             NEW.floor,
--             NEW.date,
--             NEW.time
--         );
--     END IF;
--     RETURN NULL;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER _t_bookingInsertBooker
-- AFTER INSERT ON Bookings
-- FOR EACH ROW EXECUTE FUNCTION _tf_bookingInsertBooker();


/*
@tanyjnaaman
This trigger ensures that a booking that is made is within the booking capacity. 
If it is not, it blocks the booking.
*/
CREATE OR REPLACE FUNCTION _tf_bookingWithinCapacity()
RETURNS TRIGGER AS $$
DECLARE
    _v_currentCapacity INTEGER;
    _v_capacity INTEGER;
BEGIN 
    RAISE NOTICE 'TRIGGER: Checking if booking in room %, floor %, date %, time % is within capacity', 
        NEW.room, NEW.floor, NEW.date, NEW.time;
    SELECT COUNT(*) INTO _v_currentCapacity
    FROM Participates p 
    GROUP BY p.room, p.floor, p.date, p.time;

    SELECT m.capacity INTO _v_capacity
    FROM MeetingRooms m;

    IF (_v_currentCapacity = _v_capacity) THEN
        RAISE NOTICE 'Meeting booking is full!';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER _t_bookingWithinCapacity
BEFORE INSERT ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_bookingWithinCapacity();

/*
@arijitnoobstar
This trigger ensures that a booking is made by either a Manager or Senior. 
If it is not, it blocks the booking.
*/
CREATE OR REPLACE FUNCTION _tf_bookingByBooker()
RETURNS TRIGGER AS $$
DECLARE 
    _v_etype VARCHAR(7);
BEGIN
    SELECT e.etype INTO _v_etype
    FROM Employees e
    WHERE e.eid = NEW.booker_id;

    IF(_v_etype IN ('Manager','Senior')) THEN
        RETURN NEW;
    ELSE
        RAISE NOTICE 'TRIGGER: Booking can only be made by a Senior or Manager, not a Junior';
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER _t_bookingByBooker
BEFORE INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION _tf_bookingByBooker();

/*
@arijitnoobstar
This trigger ensures that an employee with fever cannot book a meeting room.
It assumes that the latest recorded temperature reading is indicative of his/her current temperature
*/
CREATE OR REPLACE FUNCTION _tf_feverCannotBook()
RETURNS TRIGGER AS $$
DECLARE 
    _v_temperature NUMERIC;
BEGIN 
    SELECT hd.temperature INTO _v_temperature
    FROM HealthDeclaration hd
    WHERE hd.eid = NEW.booker_id
    ORDER BY(hd.date, hd.time)
    LIMIT 1;

    IF(_v_temperature > 37.5) 
    THEN
        RAISE NOTICE 'TRIGGER: Employee % has fever of temperature %, cannot book meeting', NEW.booker_id, _v_temperature;
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER _t_feverCannotBook
BEFORE INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION _tf_feverCannotBook();

/*
@arijitnoobstar
This trigger ensures that a booking is not made by a resigned employee. 
If it is, it blocks the booking.
*/
CREATE OR REPLACE FUNCTION _tf_resignedCannotBook()
RETURNS TRIGGER AS $$

BEGIN
    IF ((SELECT e.resigned_date
    FROM Employees e
    WHERE e.eid = NEW.booker_id) IS NULL)
    THEN
        RETURN NEW;
    ELSE
        RAISE NOTICE 'TRIGGER: Booking cannot be made by employees who have resigned';
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER _t_resignedCannotBook
BEFORE INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION _tf_resignedCannotBook();

/*
@arijitnoobstar
This trigger ensures that anyone who joins a meeting, joins an existing valid one .
If it is not, it blocks the participation.
*/
CREATE OR REPLACE FUNCTION _tf_checkBookingExists()
RETURNS TRIGGER AS $$
BEGIN 
    IF EXISTS(SELECT 1 FROM Bookings b
        WHERE b.room = NEW.room
        AND b.floor = NEW.floor
        AND b.date = NEW.date
        AND b.time = NEW.time)
    THEN
        RETURN NEW;
    ELSE
        RAISE NOTICE 'Employee %: Booking at floor %, room % on % at % does not exist',NEW.eid, NEW.floor, NEW.room, NEW.date, NEW.time;
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER _t_checkBookingExists
BEFORE INSERT ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_checkBookingExists();

/*
@arijitnoobstar
This trigger ensures that if a booking is approved, nobody can join it anymore.
*/
CREATE OR REPLACE FUNCTION _tf_approvalCheckToJoin()
RETURNS TRIGGER AS $$
BEGIN 
    IF((SELECT b.approver_id FROM Bookings b
        WHERE b.room = NEW.room
        AND b.floor = NEW.floor
        AND b.date = NEW.date
        AND b.time = NEW.time) IS NULL)
    THEN
        RETURN NEW;
    ELSE
        RAISE NOTICE 'Booking at floor %, room % on % at % has been approved, no more participants can join',NEW.floor, NEW.room, NEW.date, NEW.time;
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER _t_approvalCheckToJoin
BEFORE INSERT ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_approvalCheckToJoin();

/*
@arijitnoobstar
This trigger ensures that an employee with fever cannot join a meeting.
It assumes that the latest recorded temperature reading is indicative of his/her current temperature
*/
CREATE OR REPLACE FUNCTION _tf_feverCannotJoin()
RETURNS TRIGGER AS $$
DECLARE 
    _v_temperature NUMERIC;
BEGIN 
    SELECT hd.temperature INTO _v_temperature
    FROM HealthDeclaration hd
    WHERE hd.eid = NEW.eid
    ORDER BY(hd.date, hd.time)
    LIMIT 1;

    IF(_v_temperature > 37.5) 
    THEN
        RAISE NOTICE 'TRIGGER: Employee % has fever of temperature %, cannot join meeting', NEW.eid, _v_temperature;
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER _t_feverCannotJoin
BEFORE INSERT ON Participates 
FOR EACH ROW EXECUTE FUNCTION _tf_feverCannotJoin();

/*
@arijitnoobstar
This trigger ensures that a booking is not joined by a resigned employee. 
If it is, it blocks the participation.
*/
CREATE OR REPLACE FUNCTION _tf_resignedCannotJoin()
RETURNS TRIGGER AS $$

BEGIN
    IF ((SELECT e.resigned_date
    FROM Employees e
    WHERE e.eid = NEW.eid) IS NULL)
    THEN
        RETURN NEW;
    ELSE
        RAISE NOTICE 'TRIGGER: Booking cannot be joined by employees who have resigned';
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER _t_resignedCannotJoin
BEFORE INSERT ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_resignedCannotJoin();

/*
@arijitnoobstar
This trigger ensures that if a booking is approved, nobody can leave it anymore.
*/
CREATE OR REPLACE FUNCTION _tf_approvalCheckToLeave()
RETURNS TRIGGER AS $$
BEGIN 
    IF((SELECT b.approver_id FROM Bookings b
        WHERE b.room = OLD.room
        AND b.floor = OLD.floor
        AND b.date = OLD.date
        AND b.time = OLD.time) IS NULL)
    THEN
        RETURN OLD;
    ELSE
        RAISE NOTICE 'Booking at floor %, room % on % at % has been approved, no participants can leave',OLD.floor, OLD.room, OLD.date, OLD.time;
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER _t_approvalCheckToLeave
BEFORE DELETE ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_approvalCheckToLeave();

/*
@arijitnoobstar
This trigger ensures that if the booker leaves the meeting, the whole meeting is cancelled
*/
CREATE OR REPLACE FUNCTION _tf_bookerLeavesMeetingCancelled()
RETURNS TRIGGER AS $$
BEGIN 
    IF EXISTS(SELECT 1 FROM Bookings b
        WHERE b.room = OLD.room
        AND b.floor = OLD.floor
        AND b.date = OLD.date
        AND b.time = OLD.time
        AND b.booker_id = OLD.eid)
    THEN
        CALL unbook_room(OLD.room, OLD.floor, OLD.date, OLD.time, OLD.time + INTERVAL '1 hour', OLD.eid);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER _t_bookerLeavesMeetingCancelled
AFTER DELETE ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_bookerLeavesMeetingCancelled();

/* ===== FUNCTIONS ===== */

-- # HELPER #
/*
@arijitnoobstar
This is a helper function to check if a time that is keyed in is an exact hour.

IN:
@param TIME _i_ time Time variable

@return BOOLEAN      Indicates if the time is on the hour.
*/
CREATE OR REPLACE FUNCTION _f_bookingOnTheHour(IN _i_time TIME)
RETURNS BOOLEAN AS $$
BEGIN
    IF(EXTRACT(MINUTE FROM _i_time) = 0 AND EXTRACT(SECOND FROM _i_time) = 0 AND EXTRACT(milliseconds FROM _i_time) = 0)
    THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- # CORE # 


/*
@tanyjnaaman
This methods searches for rooms that are available given the entirety of a 
defined time period and given an expected booking capacity needed.

@param INTEGER _i_booking_capacity Expected booking capacity
@param DATE _i_date                Booking date
@param TIME _i_time_start          Desired start time
@param TIME _i_time_end            Desired end time

@return TABLE(_o_floor INTEGER, _o_room INTEGER, _o_did INTEGER, _o_capacity INTEGER)
*/
CREATE OR REPLACE FUNCTION search_room
    (IN _i_booking_capacity INTEGER, 
        IN _i_date DATE, 
        IN _i_time_start TIME,
        IN _i_time_end TIME)
RETURNS TABLE(_o_floor INTEGER, _o_room INTEGER, _o_did INTEGER, _o_capacity INTEGER) AS $$
DECLARE
    _v_validHour BOOLEAN;
BEGIN
    /*
    Idea: find all meeting rooms not in 
    bookings at the given time that have a valid
    capacity. But only if in time and out times are on the hour.
    */
    _v_validHour := _f_bookingOnTheHour(_i_time_start) AND _f_bookingOnTheHour(_i_time_end);
    IF (_v_validHour) THEN
        RETURN QUERY (
            SELECT floor as floor, room as room, did as did, capacity as capacity
            FROM MeetingRooms m
            WHERE NOT EXISTS (
                SELECT 
                FROM Bookings b
                WHERE m.room = b.room
                    AND m.floor = b.floor
                    AND b.time >= _i_time_start
                    AND b.time < _i_time_end
            ) AND _i_booking_capacity <= capacity
        );
    ELSE 
        RAISE NOTICE 'Start and end hours should be exact hours!';
        RETURN QUERY (
            SELECT *
            FROM MeetingRooms
            WHERE 1 = 0
        );

    END IF;
END;
$$ LANGUAGE plpgsql;


-- # HEALTH #

/*
@AryanSarswat
If an employee has a fever, we perform contact tracing by finding all employees that have 
been in the same booking as him in the last three days. This method does so. 

@param INTEGER _i_employeeId Employee ID.
@return TABLE Table of INTEGER Employee ID values that have been in close contact.
*/
CREATE OR REPLACE FUNCTION contact_tracing
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

-- # ADMIN #
/*
@AryanSarswat
This method finds all employees that do not comply with the daily health declaration. 

@param DATE _i_startDate Start date to check from.
@param DATE _i_ endDate  Date to check till. 
@return TABLE            Table of Employee ID and number of days they did not comply.
*/
CREATE OR REPLACE FUNCTION non_compliance
    (IN _i_startDate DATE, IN _i_endDate DATE)
RETURNS TABLE(employeeId INTEGER, numDays BIGINT) AS $$
BEGIN
    -- Get rid of multiple declaration per day
    DROP TABLE IF EXISTS distinctDeclaration;
    CREATE TEMP TABLE distinctDeclaration(date DATE, eid INTEGER);
    
    INSERT INTO distinctDeclaration
        SELECT DISTINCT h.date, h.eid
        FROM HealthDeclaration h;

    -- Select employeeid's whose declaration are within the date range and have not made atleast one declaration a day
    RETURN QUERY SELECT e.eid AS employeeId, ((_i_endDate - _i_startDate) - COUNT(h.eid) + 1) AS numDays
                    FROM distinctDeclaration h RIGHT JOIN Employees e
                    ON h.eid = e.eid
                    WHERE ((h.date >= _i_startDate AND h.date <= _i_endDate) OR h.date IS NULL)
                    GROUP BY e.eid
                    HAVING COUNT(h.eid) <= (_i_endDate - _i_startDate)
                    ORDER BY numDays DESC;
END;
$$ LANGUAGE plpgsql;

/*
@andrew
This function finds all bookings made by a specified employee starting from a specified
date inclusive.

@param DATE _i_startDate              Date from which to query for bookings
@param INT _i_eid                     Employee id

@return TABLE(floor INT, room INT, date DATE, startTime TIME, isApproved BOOLEAN)
*/
CREATE OR REPLACE FUNCTION view_booking_report(IN _i_startDate DATE, IN _i_eid INT)
RETURNS TABLE(_o_floor INT, _o_room INT, _o_date DATE, _o_startTime TIME, _o_isApproved BOOLEAN)
AS $$    
BEGIN
    return QUERY SELECT b.floor, b.room, b.date, b.time, b.approver_id IS NOT NULL approved
    FROM Bookings b
    WHERE b.booker_id = _i_eid
    AND b.date >= _i_startDate
    ORDER BY b.date ASC, b.time ASC;
END;
$$ LANGUAGE plpgsql;

/*
@andrew
This function finds approved bookings that a specified employee is scheduled to attend,
starting from a specified date.

@param DATE _i_startDate              Date from which to query for bookings
@param INT _i_eid                     Employee id

@return TABLE(_o_floor INT, _o_room INT, _o_date DATE, _o_startTime TIME, _o_eid INT)
*/
CREATE OR REPLACE FUNCTION view_future_meeting(IN _i_startDate DATE, IN _i_eid INT)
RETURNS TABLE(_o_floor INT, _o_room INT, _o_date DATE, _o_startTime TIME, _o_eid INT)
AS $$    
BEGIN
    return QUERY SELECT p.floor, p.room, p.date, p.time, p.eid
    FROM Participates p NATURAL JOIN Bookings b
    WHERE b.approver_id IS NOT NULL
    AND p.eid = _i_eid
    AND p.date >= _i_startDate
    ORDER BY b.date ASC, b.time ASC;
END;
$$ LANGUAGE plpgsql;

/*
@andrew
This function finds non-approved bookings made by employees from department that specified 
employee manages, starting from specified startDate. If specified employee does not manage
any department, the returned table will be empty.

@param DATE _i_startDate            Date from which to query for bookings
@param INT _i_eid                   Employee id

@return TABLE(_o_floor INT, _o_room INT, _o_date DATE, _o_startTime TIME, _o_eid INT)
*/
CREATE OR REPLACE FUNCTION view_manager_report(IN _i_startDate DATE, IN _i_eid INT)
RETURNS TABLE(_o_floor INT, _o_room INT, _o_date DATE, _o_startTime TIME, _o_eid INT)
AS $$
DECLARE managed_did INT;
BEGIN
    IF (SELECT e.etype <> 'Manager' FROM Employees e WHERE e.eid = _i_eid) 
    THEN RETURN;
    END IF;    
    SELECT e.did INTO managed_did
    FROM Employees e
    WHERE e.eid = _i_eid;

    RETURN QUERY SELECT b.floor, b.room, b.date, b.time, b.booker_id
    FROM Bookings b
    WHERE b.booker_id IN (
        SELECT e.eid
        FROM Employees e
        WHERE e.did = managed_did
    )
    AND b.approver_id IS NULL
    AND b.date >= _i_startDate
    ORDER BY b.date ASC, b.time asc;
END;
$$ LANGUAGE plpgsql;

/* ===== PROCEDURES ===== */

-- # BASIC #
/*
@tanyjnaaman
This procedure adds a department.

@param INTEGER did       Department ID
@param VARCHAR(50) dname Department name
*/
CREATE OR REPLACE PROCEDURE add_department
    (IN did INTEGER, IN dname VARCHAR(50))
AS $$
BEGIN
    INSERT INTO Departments 
    VALUES(did, dname);
END;
$$ LANGUAGE plpgsql;

/*
@tanyjnaaman

This procedure removes a department. 
@param INTEGER _i_did Department ID
*/
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

/*
@tanyjnaaman
This procedure adds a new meeting room. 

@param INTEGER _i_floor      New room floor
@param INTEGER _i_room       New room number
@param VARCHAR(50) _i_rname  New room name
@param INTEGER _i_did        New room department ID
@param INTEGER _i_capacity   New room capacity
*/
CREATE OR REPLACE PROCEDURE add_room
    (IN _i_floor INTEGER, IN _i_room INTEGER, IN _i_rname VARCHAR(50), 
    IN _i_did INTEGER, IN _i_capacity INTEGER)
AS $$
DECLARE 
    _v_defaultDate DATE:= '1971-01-01';
BEGIN
    INSERT INTO MeetingRooms
    VALUES(_i_floor, _i_room, _i_rname, _i_did, _v_defaultDate, _i_capacity);
END;
$$ LANGUAGE plpgsql;

/*
@tanyjnaaman

This method changes the capacity of a meeting room. It checks that the person changing is a manager of 
that department.

@param INTEGER _i_floor      Room floor
@param INTEGER _i_room       Room number
@param DATE date             Date of room change
@param INTEGER               Employee ID of person doing the change
*/
CREATE OR REPLACE PROCEDURE change_capacity
    (IN _i_floor INTEGER, IN _i_room INTEGER, IN _i_capacity INTEGER, IN _i_date DATE, IN _i_eid INTEGER)
AS $$
BEGIN
    -- check if employer changing capacity is a mananger of the department
    IF EXISTS (
        SELECT 1
        FROM (Departments NATURAL JOIN Employees) d, MeetingRooms m
        WHERE d.did = m.did
            AND m.room = _i_room
            AND m.floor = _i_floor
            AND d.eid = _i_eid
            AND d.etype = 'Manager'
    ) THEN
        UPDATE MeetingRooms 
        SET capacity = _i_capacity
        WHERE floor = _i_floor AND room = _i_room;
    ELSE 
        RAISE NOTICE 'Manager % is not a manager of the department', _i_eid;
    END IF;
END;
$$ LANGUAGE plpgsql;


/*
@tanyjaaman

This method adds an employee. 
It handles the assignment of employee ID and generates a unique email for 
each employee.

@param VARCHAR(50) _i_ename         Employee name
@param VARCHAR(50) _i_home_number   Employee home number
@param VARCHAR(50) _i_mobile_number Employee mobile number
@param VARCHAR(50) _i_office_number Employee office number
@param VARCHAR(7) _i_etype          Employee type; can only be 'Manager', 'Senior' or 'Junior'
@param INTEGER _i_did               Department id that employee will join
*/
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

    SELECT CONCAT(CAST(_v_eid AS VARCHAR(50)), '@office.com') INTO _v_email;

    INSERT INTO Employees
    VALUES(_v_eid, _i_ename, _v_email, _i_etype, _i_did, 
        NULL, _i_home_number, _i_mobile_number, _i_office_number);
END;
$$ LANGUAGE plpgsql;


/*
@tanyjnaaman
This method sets the resignation of an employee.

@param INTEGER _i_eid Employee id
@param DATE _i_date   Date of resignation
*/
CREATE OR REPLACE PROCEDURE remove_employee
    (IN _i_eid INTEGER, IN _i_date DATE)
AS $$
BEGIN
    UPDATE Employees
    SET resigned_date = _i_date
    WHERE eid = _i_eid;
END;
$$ LANGUAGE plpgsql;

-- # CORE #


/*
@arijitnoobstar

This method adds a booking 

@param INTEGER _i_floor         Floor number
@param INTEGER _i_room          Room number
@param DATE _i_date             Date of meeting
@param TIME _i_start_time       Start time of meeting
@param TIME _i_end_time         End time of meeting
@param INTEGER _i_eid           Employee ID
*/
CREATE OR REPLACE PROCEDURE book_room
    (IN _i_floor INTEGER, 
        IN _i_room INTEGER, 
        IN _i_date DATE,
        IN _i_start_time TIME,
        IN _i_end_time TIME,
        IN _i_eid INTEGER)
AS $$
DECLARE
    _v_booking_time TIME := _i_start_time; 
BEGIN
    -- check to make sure starting and ending time are on the hour
    IF (_f_bookingOnTheHour(_i_start_time) AND _f_bookingOnTheHour(_i_end_time))
    THEN
        WHILE _v_booking_time < _i_end_time LOOP
            -- add new row into bookings (hour by hour basis)
            INSERT INTO Bookings
            VALUES(_i_room, _i_floor, _i_date, _v_booking_time, _i_eid);
            -- add booker into updates (hour by hour basis)
            INSERT INTO Participates
            VALUES(_i_eid, _i_room, _i_floor, _i_date, _v_booking_time);
            -- increment to the next hour if needed
            _v_booking_time = _v_booking_time + INTERVAL '1 hour';
        END LOOP;
    ELSE
        RAISE EXCEPTION 'PROCEDURE: Staring and Ending hours must be on the hour';
    END IF;
END;
$$ LANGUAGE plpgsql;

/*
@arijitnoobstar

This method removes a booking.
It also sends a notice if a non-existent booking is being removed

@param INTEGER _i_floor         Floor number
@param INTEGER _i_room          Room number
@param DATE _i_date             Date of meeting
@param TIME _i_start_time       Start time of meeting
@param TIME _i_end_time         End time of meeting
@param INTEGER _i_eid           Employee ID
*/
CREATE OR REPLACE PROCEDURE unbook_room
    (IN _i_floor INTEGER, 
        IN _i_room INTEGER, 
        IN _i_date DATE,
        IN _i_start_time TIME,
        IN _i_end_time TIME,
        IN _i_eid INTEGER)
AS $$
DECLARE
    _v_booking_time TIME := _i_start_time; 
BEGIN
    WHILE _v_booking_time < _i_end_time LOOP
        -- Remove from bookings 
        IF EXISTS(SELECT 1 FROM Bookings b
        WHERE b.floor = _i_room
        AND b.room = _i_floor
        AND b.date = _i_date
        AND b.time = _v_booking_time
        AND b.booker_id = _i_eid)
        THEN
            DELETE FROM Bookings b -- approver ID also removed
            WHERE b.floor = _i_room
            AND b.room = _i_floor
            AND b.date = _i_date
            AND b.time = _v_booking_time
            AND b.booker_id = _i_eid; -- NO SABOTAGE RULE
            -- CASCADE should delete all eids in participates
        ELSE
            RAISE NOTICE 'Booking at floor %, room % on % at % does not exist',_i_floor, _i_room, _i_date, _v_booking_time;
        END IF;
        _v_booking_time = _v_booking_time + INTERVAL '1 hour';

    END LOOP;
END;
$$ LANGUAGE plpgsql;

/*
@arijitnoobstar

This method adds an employee to a meeting

@param INTEGER _i_floor         Floor number
@param INTEGER _i_room          Room number
@param DATE _i_date             Date of meeting
@param TIME _i_start_time       Start time of meeting
@param TIME _i_end_time         End time of meeting
@param INTEGER _i_eid           Employee ID
*/
CREATE OR REPLACE PROCEDURE join_meeting
    (IN _i_floor INTEGER, 
        IN _i_room INTEGER, 
        IN _i_date DATE,
        IN _i_start_time TIME,
        IN _i_end_time TIME,
        IN _i_eid INTEGER)
AS $$
DECLARE
    _v_booking_time TIME := _i_start_time;
BEGIN
    WHILE _v_booking_time < _i_end_time LOOP
        -- add employee into updates (hour by hour basis)
        INSERT INTO Participates
        VALUES(_i_eid, _i_room, _i_floor, _i_date, _v_booking_time);
        _v_booking_time = _v_booking_time + INTERVAL '1 hour';
    END LOOP;
END;
$$ LANGUAGE plpgsql;

/*
@arijitnoobstar

This method removes an employee from a meeting.
It also sends a notice if an employee is being removed from a non-existent meeting.

@param INTEGER _i_floor         Floor number
@param INTEGER _i_room          Room number
@param DATE _i_date             Date of meeting
@param TIME _i_start_time       Start time of meeting
@param TIME _i_end_time         End time of meeting
@param INTEGER _i_eid           Employee ID
*/
CREATE OR REPLACE PROCEDURE leave_meeting
    (IN _i_floor INTEGER, 
        IN _i_room INTEGER, 
        IN _i_date DATE,
        IN _i_start_time TIME,
        IN _i_end_time TIME,
        IN _i_eid INTEGER)
AS $$
DECLARE
    _v_booking_time TIME := _i_start_time; 
BEGIN
    WHILE _v_booking_time < _i_end_time LOOP
        -- Remove from participates
        IF EXISTS(SELECT 1 FROM Participates p
        WHERE p.floor = _i_room
        AND p.room = _i_floor
        AND p.date = _i_date
        AND p.time = _v_booking_time
        AND p.eid = _i_eid)
        THEN 
            DELETE FROM Participates p -- approver ID also removed
            WHERE p.floor = _i_floor
            AND p.room = _i_room
            AND p.date = _i_date
            AND p.time = _v_booking_time
            AND p.eid = _i_eid; -- NO SABOTAGE RULE
        ELSE
            RAISE NOTICE 'Employee % does not have a meeting at floor %, room % on % at %',_i_eid, _i_floor, _i_room, _i_date, _v_booking_time;
        END IF;
        _v_booking_time = _v_booking_time + INTERVAL '1 hour';
        -- CASCADE should delete all eids in participates
    END LOOP;
END;
$$ LANGUAGE plpgsql;

/*
@AryanSarswat
This procedure is used to approve a booking.

# TODO - bound start and end hour to hour specifically

@param INTEGER _i_roomNumber  Room number
@param INTEGER _i_floorNumber Floor number
@param DATE _i_inputDate      Date of meeting
@param TIME _i_startHour      Start hour
@param TIME _i_endHour        End hour
@param INTEGER _i_managerEid  Manager ID of manager approving
*/
CREATE OR REPLACE PROCEDURE approve_meeting
    (IN _i_roomNumber INTEGER, IN _i_floorNumber INTEGER, IN _i_inputDate DATE, IN _i_startHour TIME, IN _i_endHour TIME, IN _i_managerEid INTEGER)
AS $$

<<BeginLabel>>
DECLARE
    _v_tempStartHour TIME := _i_startHour;
    _v_employeeId INTEGER;
    _v_employeeDept INTEGER;
    _v_managerDept INTEGER;
BEGIN   
    -- Ensure input is correct
    IF (_i_startHour > _i_endHour) THEN
        EXIT BeginLabel;
    END IF;
    
    <<MainLoop>>
    LOOP
        --All the bookings have been approved then exit
        EXIT WHEN _v_tempStartHour >= _i_endHour;
        
        -- Checks whether employee's department is the same as the manager's department
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

       
        -- If manger department is null he has resigned or doesnt exist
        IF (_v_managerDept IS NULL) THEN
            RAISE EXCEPTION 'Manager is Resigned';
        END IF;
        
        -- Approve all bookings until employeeDept != mangerDept
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

-- # HEALTH #
/*
@AryanSarswat
This procedure is used for daily declaration of temperature. 
Time is taken as an input so that morning and afternoon fever events are distinct.

@param INTEGER _i_eid         Employee id
@param DATE _i_date           Date of declaration
@param NUMERIC _i_temperature Temperature declared
@param TIME _i_ time          Time of declaration
*/
CREATE OR REPLACE PROCEDURE declare_health
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
