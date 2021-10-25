\i 'schema.sql'
\i 'proc.sql'

-- Create + approve booking --
/* Cases:
1) search_room
2) unbook_room
3) view_booking_report
4) join_meeting
5) leave_meeting
6) view_future_meeting
7) view_manager_report
*/

-- TEST 1: Booking + approval + search_room
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

-- TEST 2: book_room + unbook_room + search_room    
/*
Test Case:
1) Room should start as available
2) Post-booking should no longer available
3) Post-un-book should be available
3.5) booked room should be unbookable
3.6) unbooked room should not be unbookable, and throw notice

Expected:
BEGIN
CALL
CALL
CALL
CALL
CALL
 _o_floor | _o_room | _o_did | _o_capacity
----------+---------+--------+-------------
        1 |       1 |      1 |          10
        2 |       2 |      1 |          10
(2 rows)


psql:integration_test_1.sql:107: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
 _o_floor | _o_room | _o_did | _o_capacity
----------+---------+--------+-------------
        2 |       2 |      1 |          10
(1 row)


CALL
 _o_floor | _o_room | _o_did | _o_capacity
----------+---------+--------+-------------
        1 |       1 |      1 |          10
        2 |       2 |      1 |          10
(2 rows)


psql:integration_test_1.sql:115: NOTICE:  Booking at floor 1, room 1 on 2021-01-01 at 10:00:00 does not exist
CALL
ROLLBACK
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

    -- UNBOOK
    CALL unbook_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
    SELECT * FROM search_room(10, '2021-1-1'::DATE, '10:00:00'::TIME, '13:00:00'::TIME);

    -- UNBOOK AGAIN
    CALL unbook_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
ROLLBACK;

-- TEST 3: All Booking + view_report
/*
Test Case:
1) Before booking, report should be empty
2) After booking, the unapproved booking should be in the report
3) After approval, report should reflect approval status
4) Post-approval booking should still be unbookable
5) Report should now be empty

EXPECTED:
BEGIN
CALL
CALL
CALL
CALL
CALL
psql:integration_test_1.sql:173: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
 _o_floor | _o_room |  _o_date   | _o_starttime | _o_isapproved
----------+---------+------------+--------------+---------------
        1 |       1 | 2021-01-01 | 10:00:00     | f
(1 row)


CALL
 _o_floor | _o_room |  _o_date   | _o_starttime | _o_isapproved
----------+---------+------------+--------------+---------------
        1 |       1 | 2021-01-01 | 10:00:00     | t
(1 row)


CALL
 _o_floor | _o_room | _o_date | _o_starttime | _o_isapproved
----------+---------+---------+--------------+---------------
(0 rows)


ROLLBACK
*/
BEGIN;
    -- SETUP
    CALL add_department(1, 'firstDep');
    CALL add_room(1, 1, 'toBookRoom', 1, 10);
    CALL add_room(2, 2, 'dummyRoom', 1, 10);
    CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
    CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);

    -- BOOK
    CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
    SELECT * FROM view_booking_report('2021-1-1', 2);

    -- APPROVE
    CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
    SELECT * FROM view_booking_report('2021-1-1', 2);

    -- UNBOOK
    CALL unbook_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
    SELECT * FROM view_booking_report('2021-1-1', 2);
ROLLBACK;

-- TEST 4: Booking + Join with successful leaving
-- book + join + leave + view_future_meeting
/*
Test Case:
1) After booking, can join and leave meeting
2) After booking, the unapproved booking should be in the report
3) After approval, report should reflect approval status
*/
BEGIN;
    -- SETUP
    CALL add_department(1, 'firstDep');
    CALL add_room(1, 1, 'toBookRoom', 1, 10);
    CALL add_room(2, 2, 'dummyRoom', 1, 10);
    CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
    CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);

    -- BOOK
    CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
    SELECT * FROM view_booking_report('2021-1-1', 1);

    -- APPROVE
    CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
    SELECT * FROM view_booking_report('2021-1-1', 1);

    -- UNBOOK
    CALL unbook_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
    SELECT * FROM search_room(10, '2021-1-1'::DATE, '10:00:00'::TIME, '13:00:00'::TIME);
ROLLBACK;

-- TEST 5: Booking + Join with approval

-- TEST 6: Booking + Join with deletion

-- TEST 7: manager report + book with approval

-- TEST 8: manager report + book with deletion