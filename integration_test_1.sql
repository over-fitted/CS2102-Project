\i 'schema.sql'
\i 'proc.sql'

-- Create + approve booking --
/* Cases:
1) search_room
2) unbook_room
3) join_meeting
4) view_booking_report
5) view_future_meeting
6) view_manager_report
*/

-- TEST 1: Booking + search_room
/*
Test Case:
1) Room should start as available
2) Post-booking should no longer available
3) Post-approval should remain not available

Expected:
 _o_floor | _o_room | _o_did | _o_capacity
----------+---------+--------+-------------
        1 |       1 |      1 |          10
        2 |       2 |      1 |          10
(2 rows)


psql:integration_test_1.sql:61: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
 _o_floor | _o_room | _o_did | _o_capacity 
----------+---------+--------+-------------
        2 |       2 |      1 |          10
(1 row)


CALL
 _o_floor | _o_room | _o_did | _o_capacity
----------+---------+--------+-------------
        2 |       2 |      1 |          10
(1 row)
*/
BEGIN;
    -- SETUP
    CALL add_department(1, 'firstDep');
    CALL add_room(1, 1, 'toBookRoom', 1, 10);
    CALL add_room(2, 2, 'dummyRoom', 1, 10);
    CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
    CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);

    -- PRE-BOOKING CALLS
    SELECT * FROM search_room(10, '2021-1-1', '10:00:00', '13:00:00');

    -- BOOK
    CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
    SELECT * FROM search_room(10, '2021-1-1'::DATE, '10:00:00'::TIME, '13:00:00'::TIME);

    -- APPROVE
    CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
    SELECT * FROM search_room(10, '2021-1-1'::DATE, '10:00:00'::TIME, '13:00:00'::TIME);
ROLLBACK;

-- TEST 2: Booking + unbook_room
BEGIN;
    -- -- SETUP
    -- CALL add_department(1, 'firstDep');
    -- CALL add_room(1, 1, 'toBookRoom', 1, 10);
    -- CALL add_room(2, 2, 'dummyRoom', 1, 10);
    -- CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
    -- CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);

    -- -- PRE-BOOKING CALLS
    -- SELECT * FROM search_room(10, '2021-1-1', '10:00:00', '13:00:00');

    -- -- BOOK
    -- CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
    -- SELECT * FROM search_room(10, '2021-1-1'::DATE, '10:00:00'::TIME, '13:00:00'::TIME);
    -- SELECT * FROM Bookings;

    -- -- APPROVE
    -- CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
    -- SELECT * FROM search_room(10, '2021-1-1'::DATE, '10:00:00'::TIME, '13:00:00'::TIME);
ROLLBACK;