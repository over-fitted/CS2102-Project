
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

DROP TRIGGER IF EXISTS _t_bookingByBooker ON Bookings;
CREATE TRIGGER _t_bookingByBooker
BEFORE INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION _tf_bookingByBooker();

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

DROP TRIGGER IF EXISTS _t_feverCannotBook ON Bookings;
CREATE TRIGGER _t_feverCannotBook
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
DROP TRIGGER IF EXISTS _t_feverCannotJoin ON Participates;
CREATE TRIGGER _t_feverCannotJoin
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

DROP TRIGGER IF EXISTS _t_checkBookingExists ON Participates;
CREATE TRIGGER _t_checkBookingExists
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

DROP TRIGGER IF EXISTS _t_approvalCheckToJoin ON Participates;
CREATE TRIGGER _t_approvalCheckToJoin
BEFORE INSERT ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_approvalCheckToJoin();


-- -- ensure that participant does not have a meeting at the exact same time and place
-- CREATE OR REPLACE FUNCTION _tf_checkSimultaneousMeetings()
-- RETURNS TRIGGER AS $$
-- BEGIN 
--     -- check on an existing meeting at the same time and place
--     IF EXISTS(SELECT 1 FROM Participates p
--         WHERE p.eid = NEW.eid
--         AND b.date = NEW.date
--         AND b.time = NEW.time)
--     THEN
--         RAISE NOTICE 'Employee eid: % already has a meeting at %, %',NEW.eid, NEW.date, NEW.time;
--         RETURN NULL;
--     ELSE
--         RETURN NEW;
--     END IF;
-- END;
-- $$ LANGUAGE plpgsql;

-- DROP TRIGGER IF EXISTS _t_checkSimultaneousMeetings ON Participates;
-- CREATE TRIGGER _t_checkSimultaneousMeetings
-- BEFORE INSERT ON Participates
-- FOR EACH ROW EXECUTE FUNCTION _tf_checkSimultaneousMeetings();


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

DROP TRIGGER IF EXISTS _t_approvalCheckToLeave ON Participates;
CREATE TRIGGER _t_approvalCheckToLeave
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