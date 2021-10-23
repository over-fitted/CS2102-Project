-- ### ensure that booking is done by either a senior or manager
CREATE OR REPLACE FUNCTION _tf_bookingByBooker()
RETURNS TRIGGER AS $$
BEGIN
    IF(NEW.etype IN ('Manager','Senior')) THEN
        RETURN NEW;
    ELSE
        RAISE NOTICE 'TRIGGER: Booking can only be made by a Senior or Manager, not a Junior';
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER _t_bookingByBooker
BEFORE INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION _tf_bookingByBooker();

-- ### A Booking which is not immedietely approved by manager is removed
CREATE OR REPLACE FUNCTION _tf_bookingNotApproved() 
RETURNS TRIGGER AS $$

DECLARE
    approver INTEGER;

BEGIN
    -- ### Checking if manager has approved
    SELECT b.approver_id INTO approver
    FROM Bookings b
    WHERE b.floor = NEW.floor
        AND b.room = NEW.room
        AND b.date = NEW.date
        AND b.time = NEW.time
        AND b.booker_id = NEW.booker_id;
    
    IF (approver IS NULL) THEN
        RAISE EXCEPTION 'Booking is not approved by manager, Booking deleted';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _tf_feverCannotMeet()
RETURNS TRIGGER AS $$
DECLARE 
    _v_temperature INTEGER;
BEGIN 
    SELECT hd.temperature INTO _v_temperature
    FROM HealthDeclaration hd
    WHERE hd.eid = NEW.eid
    ORDER BY(hd.date, hd.time)
    LIMIT 1;

    IF(_v_temperature > 37.5) 
    THEN
        RAISE NOTICE 'TRIGGER: Employee % has fever of temperature %, cannot join/book meeting', NEW.eid, _v_temperature;
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

CREATE OR REPLACE TRIGGER _t_feverCannotBook
BEFORE INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION _tf_feverCannotMeet();


-- function to check if a time variable is exactly on the hour
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


CREATE OR REPLACE PROCEDURE book_room
    (IN _i_floor INTEGER, 
        IN _i_room INTEGER, 
        IN _i_date DATE,
        IN _i_start_time TIME,
        IN _i_end_time TIME,
        IN _i_eid INTEGER)
AS $$
    /*
    Idea: book room as if it is available, use triggers to enforce
    the constraints (1) booking only made by bookable (2) booking
    slots must be free. Approver ID is set to be null at the start.
    (3) booker does not have fever. Booker is added to participates
    relation too (4) participates slot is free too (redundancy check)
    (5) start and end time MUST be on the hour
    */
DECLARE
    _v_booking_time INTEGER := _i_start_time; 
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
            _v_booking_time = DATEADD(HOUR, 1, _v_booking_time);
        END LOOP;
    ELSE
        RAISE EXCEPTION 'PROCEDURE: Staring and Ending hours must be on the hour';
    END IF;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE unbook_room
    (IN _i_floor INTEGER, 
        IN _i_room INTEGER, 
        IN _i_date DATE,
        IN _i_start_time TIME,
        IN _i_end_time TIME,
        IN _i_eid INTEGER)
AS $$
    /*
    Idea: remove booking. no sabotage rule enforced via check
    approver ID also removed by deleting booking. Participants
    should be automatically removed via CASCADE. Trigger check
    used to ensure such a booking even exists [does nothing]
    */
DECLARE
    _v_booking_time INTEGER := _i_start_time; 
BEGIN
    WHILE _v_booking_time < _v_end_time LOOP
        -- Remove from bookings 
        DELETE FROM Bookings b -- approver ID also removed
        WHERE b.floor = _i_room
        AND b.room = _i_floor
        AND b.date = _i_date
        AND b.time = _v_booking_time
        AND b.booker_id = _v_eid; -- NO SABOTAGE RULE
        _v_booking_time = DATEADD(HOUR, 1, _v_booking_time);
        -- CASCADE should delete all eids in participates
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- use the same trigger function _tf_feverCannotMeet for the trigger _t_feverCannotJoin
CREATE OR REPLACE TRIGGER _t_feverCannotJoin
BEFORE INSERT ON Participates -- to prefer employees with fever from joining
FOR EACH ROW EXECUTE FUNCTION _tf_feverCannotMeet();


-- ensure that booking exists before joining a meeting/booking
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
        RAISE NOTICE 'Booking at floor %, room % on % at % does not exist',NEW.floor, NEW.room, NEW.date, NEW.time;
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER _t_checkBookingExists
BEFORE INSERT ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_checkBookingExists();

-- ensure that booking has not yet been approved, else participant cannot be added
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

CREATE OR REPLACE TRIGGER _t_approvalCheckToJoin
BEFORE INSERT ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_approvalCheckToJoin();

CREATE OR REPLACE PROCEDURE join_meeting
    (IN _i_floor INTEGER, 
        IN _i_room INTEGER, 
        IN _i_date DATE,
        IN _i_start_time TIME,
        IN _i_end_time TIME,
        IN _i_eid INTEGER)
AS $$
    /*
    Idea: join meeting and the following constraints (1)
    if approved, employee cannot join, (2) if booking even exists
    (3) no fever (4) employee hasnt already taken a slot (5) within capacity
    */
DECLARE
    _v_booking_time INTEGER := _i_start_time;
BEGIN
    WHILE _v_booking_time < _i_end_time LOOP
        -- add employee into updates (hour by hour basis)
        INSERT INTO Participates
        VALUES(_i_eid, _i_room, _i_floor, _i_date, _v_booking_time);
        _v_booking_time = DATEADD(HOUR, 1, _v_booking_time);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ensure that booking has not yet been approved, else participant cannot be added
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
        RAISE NOTICE 'Booking at floor %, room % on % at % has been approved, no more participants can leave',OLD.floor, OLD.room, OLD.date, OLD.time;
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER _t_approvalCheckToLeave
BEFORE DELETE ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_approvalCheckToLeave();

CREATE OR REPLACE PROCEDURE leave_meeting
    (IN _i_floor INTEGER, 
        IN _i_room INTEGER, 
        IN _i_date DATE,
        IN _i_start_time TIME,
        IN _i_end_time TIME,
        IN _i_eid INTEGER)
AS $$
    /*
    Idea: leave meeting and the following constraints (1)
    if approved, employee cannot leave, (2) if booking even exists [does nothing]
    (3) if employee is not in meeting, do nothing (what does do nothing mean?)
    */
DECLARE
    _v_booking_time INTEGER := _i_start_time; 
BEGIN
    WHILE _v_booking_time < _i_end_time LOOP
        -- Remove from bookings 
        DELETE FROM Participates p -- approver ID also removed
        WHERE p.floor = _i_floor
        AND p.room = _i_room
        AND p.date = _i_date
        AND p.time = _i_booking_time
        AND p.eid = _i_eid; -- NO SABOTAGE RULE
        _v_booking_time = DATEADD(HOUR, 1, _v_booking_time);
        -- CASCADE should delete all eids in participates
    END LOOP;
END;
$$ LANGUAGE plpgsql;
/* # TRIGGERS & TRIGGER FUNCTIONS # */

/* ## Enforcing data integrity ## */
/* Note: All triggers here are initially deferred. ## */

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

-- ### All Bookings must have at least one participant, which is the booker ###
CREATE OR REPLACE FUNCTION _tf_bookingInsertBooker()
RETURNS TRIGGER AS $$
BEGIN 
    RAISE NOTICE 'TRIGGER: Inserting booker % into booking he made in room %, floor %, date %, time %', 
        NEW.booker_id, NEW.room, NEW.floor, NEW.date, NEW.time;
    -- see if new row is already in participates
    IF NOT EXISTS (
        SELECT 1
        FROM Participates p
        WHERE p.eid = NEW.booker_id
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
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ### Returns employee_id and number of times they default on declaring temperature
CREATE OR REPLACE FUNCTION _f_non_compliance
    (IN _i_startDate DATE, IN _i_endDate DATE)
RETURNS TABLE(employeeId INTEGER, numDays BIGINT) AS $$
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

CREATE OR REPLACE TRIGGER _t_bookingWithinCapacity
BEFORE INSERT ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_bookingWithinCapacity();

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
    RETURN NULL;
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

-- ### Changing meeting room capacity ###
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
<<<<<<< HEAD
>>>>>>> main
$$ LANGUAGE plpgsql;
=======
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_booking_report(IN startDate DATE, IN eid INT)
RETURNS TABLE(floor INT, room INT, date DATE, startTime TIMESTAMP, isApproved BOOLEAN)
AS $$    
BEGIN
    return QUERY SELECT b.floor, b.room, b.date, b.time, b.approver_id IS NOT NULL approved
    FROM Bookings b
    WHERE b.booker_id = eid
    AND b.date > startDate
    ORDER BY b.date;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_future_meeting(IN startDate DATE, IN employee_id INT)
RETURNS TABLE(floor INT, room INT, date DATE, startTime TIMESTAMP, eid INT)
AS $$    
BEGIN
    return QUERY SELECT p.floor, p.room, p.date, p.time, p.eid
    FROM Participates p NATURAL JOIN Bookings b
    WHERE b.approver_id IS NOT NULL
    AND p.eid = employee_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_manager_report(IN startDate DATE, IN employee_id INT)
RETURNS TABLE(floor INT, room INT, date DATE, startTime TIMESTAMP, eid INT)
AS $$
DECLARE managed_did INT;
BEGIN
    SELECT e.did INTO managed_did
    FROM Employees e
    WHERE e.eid = employee_id;

    RETURN QUERY SELECT b.floor, b.room, b.date, b.time, b.booker_id
    FROM Bookings b
    WHERE b.booker_id IN (
        SELECT e.eid
        FROM Employees e
        WHERE e.did = managed_did
    )
    AND b.approver_id IS NULL
    AND b.date > startDate
    ORDER BY b.date ASC, b.time asc;
END;
$$ LANGUAGE plpgsql;
>>>>>>> main
