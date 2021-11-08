\i 'schema.sql'
\i 'proc.sql'

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
-- BEGIN;
--     -- SETUP
--     CALL add_department(1, 'firstDep');
--     CALL add_room(1, 1, 'toBookRoom', 1, 10);
--     CALL add_room(2, 2, 'dummyRoom', 1, 10);
--     CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
--     CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);

--     -- PRE-BOOKING CALLS
--     SELECT * FROM search_room(10, '2021-1-1', '10:00:00', '13:00:00');

--     -- BOOK
--     CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM search_room(10, '2021-1-1'::DATE, '10:00:00'::TIME, '13:00:00'::TIME);

--     -- APPROVE
--     CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     SELECT * FROM search_room(10, '2021-1-1'::DATE, '10:00:00'::TIME, '13:00:00'::TIME);
-- ROLLBACK;
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
-- BEGIN;
--     -- SETUP
--     CALL add_department(1, 'firstDep');
--     CALL add_room(1, 1, 'toBookRoom', 1, 10);
--     CALL add_room(2, 2, 'dummyRoom', 1, 10);
--     CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
--     CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);

--     -- PRE-BOOKING CALLS
--     SELECT * FROM search_room(10, '2021-1-1', '10:00:00', '13:00:00');

--     -- BOOK
--     CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM search_room(10, '2021-1-1'::DATE, '10:00:00'::TIME, '13:00:00'::TIME);

--     -- UNBOOK
--     CALL unbook_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM search_room(10, '2021-1-1'::DATE, '10:00:00'::TIME, '13:00:00'::TIME);

--     -- UNBOOK AGAIN
--     CALL unbook_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
-- ROLLBACK;

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
-- BEGIN;
--     -- SETUP
--     CALL add_department(1, 'firstDep');
--     CALL add_room(1, 1, 'toBookRoom', 1, 10);
--     CALL add_room(2, 2, 'dummyRoom', 1, 10);
--     CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
--     CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);

--     -- BOOK
--     CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM view_booking_report('2021-1-1', 2);

--     -- APPROVE
--     CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     SELECT * FROM view_booking_report('2021-1-1', 2);

--     -- UNBOOK
--     CALL unbook_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM view_booking_report('2021-1-1', 2);
-- ROLLBACK;

-- TEST 4: Default join behaviour
-- book + join + leave
/*
Test Case:
1) After meeting is booked, booker is a participant.
2) Other people can join the meeting up to capacity which includes the booker.
3) Post-capacity, new people cannot join.
4) Non-bookers can leave the meeting.
5) Booker can leave the meeting, but meeting would be cancelled.

EXPECTED:
BEGIN
CALL
CALL
CALL
CALL
CALL
CALL
CALL
psql:integration_test_1.sql:213: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   1 |    1 |     1 | 2021-01-01 | 10:00:00
(1 row)


 room | floor |    date    |   time   | booker_id | approver_id
------+-------+------------+----------+-----------+-------------
    1 |     1 | 2021-01-01 | 10:00:00 |         1 |
(1 row)


psql:integration_test_1.sql:218: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:219: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   1 |    1 |     1 | 2021-01-01 | 10:00:00
   2 |    1 |     1 | 2021-01-01 | 10:00:00
   3 |    1 |     1 | 2021-01-01 | 10:00:00
(3 rows)


psql:integration_test_1.sql:223: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
psql:integration_test_1.sql:223: NOTICE:  Meeting booking is full!
CALL
 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   1 |    1 |     1 | 2021-01-01 | 10:00:00
   2 |    1 |     1 | 2021-01-01 | 10:00:00
   3 |    1 |     1 | 2021-01-01 | 10:00:00
(3 rows)


CALL
 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   1 |    1 |     1 | 2021-01-01 | 10:00:00
   3 |    1 |     1 | 2021-01-01 | 10:00:00
(2 rows)


CALL
 eid | room | floor | date | time
-----+------+-------+------+------
(0 rows)


 room | floor | date | time | booker_id | approver_id
------+-------+------+------+-----------+-------------
(0 rows)


psql:integration_test_1.sql:236: NOTICE:  Employee 3 does not have a meeting at floor 1, room 1 on 2021-01-01 at 10:00:00
CALL
 eid | room | floor | date | time
-----+------+-------+------+------
(0 rows)


ROLLBACK
*/
-- BEGIN;
--     -- SETUP
--     CALL add_department(1, 'firstDep');
--     CALL add_room(1, 1, 'toBookRoom', 1, 3);
--     CALL add_room(2, 2, 'dummyRoom', 1, 3);
--     CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
--     CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);
--     CALL add_employee('third junior', '32345678', '32345678', '32345678', 'Junior', 1);
--     CALL add_employee('fourth junior', '42345678', '42345678', '42345678', 'Junior', 1);
    
--     -- BOOK
--     CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     SELECT * FROM Participates;
--     SELECT * FROM Bookings;

--     -- JOIN till capacity
--     CALL join_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     CALL join_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 3);
--     SELECT * FROM Participates;

--     -- JOIN past capacity
--     CALL join_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 4);
--     SELECT * FROM Participates;

--     -- LEAVE normal
--     CALL leave_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM Participates;

--     -- LEAVE booker
--     CALL leave_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);    
--     SELECT * FROM Participates;
--     SELECT * FROM Bookings;

--     -- LEAVE post-booker
--     CALL leave_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 3);
--     SELECT * FROM Participates;
-- ROLLBACK;

-- TEST 5: Booking + Join with approval block
/*
Test case:
After booking is approved, participants cannot leave the meeting, and other participants cannot join the meeting

EXPECTED:
BEGIN
CALL
CALL
CALL
CALL
CALL
CALL
psql:integration_test_1.sql:389: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
 _o_floor | _o_room | _o_date | _o_starttime | _o_eid
----------+---------+---------+--------------+--------
(0 rows)


psql:integration_test_1.sql:393: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
 _o_floor | _o_room | _o_date | _o_starttime | _o_eid
----------+---------+---------+--------------+--------
(0 rows)


CALL
 _o_floor | _o_room |  _o_date   | _o_starttime | _o_eid
----------+---------+------------+--------------+--------
        1 |       1 | 2021-01-01 | 10:00:00     |      2
(1 row)


psql:integration_test_1.sql:401: NOTICE:  Booking at floor 1, room 1 on 2021-01-01 at 10:00:00 has been approved, no participants can leave
CALL
 _o_floor | _o_room |  _o_date   | _o_starttime | _o_eid
----------+---------+------------+--------------+--------
        1 |       1 | 2021-01-01 | 10:00:00     |      2
(1 row)


psql:integration_test_1.sql:405: NOTICE:  Booking at floor 1, room 1 on 2021-01-01 at 10:00:00 has been approved, no more participants can join
CALL
 _o_floor | _o_room | _o_date | _o_starttime | _o_eid
----------+---------+---------+--------------+--------
(0 rows)


psql:integration_test_1.sql:409: NOTICE:  Booking at floor 1, room 1 on 2021-01-01 at 10:00:00 has been approved, no participants can leave
CALL
 _o_floor | _o_room |  _o_date   | _o_starttime | _o_eid
----------+---------+------------+--------------+--------
        1 |       1 | 2021-01-01 | 10:00:00     |      1
(1 row)


 _o_floor | _o_room |  _o_date   | _o_starttime | _o_eid
----------+---------+------------+--------------+--------
        1 |       1 | 2021-01-01 | 10:00:00     |      2
(1 row)


ROLLBACK
*/
-- BEGIN;
--     -- SETUP
--     CALL add_department(1, 'firstDep');
--     CALL add_room(1, 1, 'toBookRoom', 1, 10);
--     CALL add_room(2, 2, 'dummyRoom', 1, 10);
--     CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
--     CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);
--     CALL add_employee('third junior', '32345678', '32345678', '32345678', 'Junior', 1);

--     -- BOOK
--     CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     SELECT * FROM view_future_meeting('2021-1-1', 1);

--     -- JOIN
--     CALL join_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM view_future_meeting('2021-1-1', 2);

--     -- APPROVE
--     CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     SELECT * FROM view_future_meeting('2021-1-1', 2);

--     -- BLOCKED LEAVE
--     CALL leave_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM view_future_meeting('2021-1-1', 2);

--     -- BLOCKED JOIN
--     CALL join_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 3);
--     SELECT * FROM view_future_meeting('2021-1-1', 3);

--     -- LEAVE booker
--     CALL leave_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     SELECT * FROM view_future_meeting('2021-1-1', 1);
--     SELECT * FROM view_future_meeting('2021-1-1', 2);
-- ROLLBACK;

-- TEST 6: Booking + Join with deletion
/*
Test Case:
After meeting is deleted, all participants are automatically removed, regardless of meeting approval status

EXPECTED:
BEGIN
CALL
CALL
CALL
CALL
CALL
psql:integration_test_1.sql:427: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:428: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
CALL
 _o_floor | _o_room |  _o_date   | _o_starttime | _o_eid
----------+---------+------------+--------------+--------
        1 |       1 | 2021-01-01 | 10:00:00     |      1
(1 row)


CALL
 _o_floor | _o_room | _o_date | _o_starttime | _o_eid
----------+---------+---------+--------------+--------
(0 rows)


ROLLBACK
*/
-- BEGIN;
--     -- SETUP
--     CALL add_department(1, 'firstDep');
--     CALL add_room(1, 1, 'toBookRoom', 1, 10);
--     CALL add_room(2, 2, 'dummyRoom', 1, 10);
--     CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
--     CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);

--     -- BOOK, JOIN, APPROVE
--     CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     CALL join_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     SELECT * FROM view_future_meeting('2021-1-1', 1);

--     -- DELETE meeting
--     CALL unbook_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM view_future_meeting('2021-1-1', 1);
-- ROLLBACK;

-- TEST 7: DEFAULT: manager report + book + approval
/*
UNIT TESTED ASSUMPTIONS:
1) view_manager_report shows bookings from given date onwards, not prior

Test Case:
1) After bookings created, manager report should show bookings from same department
        1a) non-managers should have null shown
2) After bookings are approved, they should not be viewable from the report
3) Booking from other departments should not be visible

EXPECTED:
ROLLBACK
BEGIN
CALL
CALL
CALL
CALL
CALL
CALL
CALL
psql:integration_test_1.sql:485: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
 _o_floor | _o_room |  _o_date   | _o_starttime | _o_eid
----------+---------+------------+--------------+--------
        1 |       1 | 2021-01-01 | 10:00:00     |      2
(1 row)


 _o_floor | _o_room | _o_date | _o_starttime | _o_eid
----------+---------+---------+--------------+--------
(0 rows)


CALL
 _o_floor | _o_room | _o_date | _o_starttime | _o_eid
----------+---------+---------+--------------+--------
(0 rows)


psql:integration_test_1.sql:494: NOTICE:  TRIGGER: Checking if booking in room 2, floor 2, date 2021-01-01, time 10:00:00 is within capacity
CALL
 _o_floor | _o_room | _o_date | _o_starttime | _o_eid
----------+---------+---------+--------------+--------
(0 rows)


ROLLBACK
*/
-- BEGIN;
--     -- SETUP
--     CALL add_department(1, 'firstDep');
--     CALL add_department(2, 'secondDep');
--     CALL add_room(1, 1, 'toBookRoom', 1, 10);
--     CALL add_room(2, 2, 'dummyRoom', 2, 10);
--     CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
--     CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);
--     CALL add_employee('third manager', '32345678', '32345678', '32345678', 'Manager', 2);

--     -- BOOK only - only manager should show the meeting
--     CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM view_manager_report('2021-1-1', 1);
--     SELECT * FROM view_manager_report('2021-1-1', 2);

--     -- APPROVED - should show null
--     CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     SELECT * FROM view_manager_report('2021-1-1', 1);

--     -- WRONG DEPARTMENT
--     CALL book_room(2, 2, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 3);
--     SELECT * FROM view_manager_report('2021-1-1', 1);
-- ROLLBACK;

-- TEST 8: manager report + book with deletion
/*
Test Case:
1) After bookings created, manager report should show bookings from same department
2) After bookings are deleted, they should no longer be viewable from the report

EXPECTED:
BEGIN
CALL
CALL
CALL
CALL
CALL
CALL
CALL
psql:integration_test_1.sql:553: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
 _o_floor | _o_room |  _o_date   | _o_starttime | _o_eid
----------+---------+------------+--------------+--------
        1 |       1 | 2021-01-01 | 10:00:00     |      2
(1 row)


CALL
 _o_floor | _o_room | _o_date | _o_starttime | _o_eid
----------+---------+---------+--------------+--------
(0 rows)


ROLLBACK
*/
-- BEGIN;
--     -- SETUP
--     CALL add_department(1, 'firstDep');
--     CALL add_department(2, 'secondDep');
--     CALL add_room(1, 1, 'toBookRoom', 1, 10);
--     CALL add_room(2, 2, 'dummyRoom', 2, 10);
--     CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
--     CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);
--     CALL add_employee('third manager', '32345678', '32345678', '32345678', 'Manager', 2);

--     -- BOOK - show the meeting
--     CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM view_manager_report('2021-1-1', 1);

--     -- DELETED - should show null
--     CALL unbook_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM view_manager_report('2021-1-1', 1);
-- ROLLBACK;

-- TEST 9: change capacity + bookings
/*
Test case:
both approved and non-approved bookings with excess capacity deleted, but not those within limits
10: app, excess
11: app, limit
12: non-app, excess
13: non-app, limit

EXPECTED:
BEGIN
CALL
CALL
CALL
CALL
CALL
CALL
psql:integration_test_1.sql:604: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:605: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 11:00:00 is within capacity
CALL
psql:integration_test_1.sql:606: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 12:00:00 is within capacity
CALL
psql:integration_test_1.sql:607: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 13:00:00 is within capacity
CALL
psql:integration_test_1.sql:609: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:610: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 11:00:00 is within capacity
CALL
psql:integration_test_1.sql:611: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 12:00:00 is within capacity
CALL
psql:integration_test_1.sql:612: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 13:00:00 is within capacity
CALL
psql:integration_test_1.sql:613: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:614: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-01-01, time 12:00:00 is within capacity
CALL
CALL
CALL
 room | floor |    date    |   time   | booker_id | approver_id
------+-------+------------+----------+-----------+-------------
    1 |     1 | 2021-01-01 | 12:00:00 |         2 |
    1 |     1 | 2021-01-01 | 13:00:00 |         2 |
    1 |     1 | 2021-01-01 | 10:00:00 |         2 |           2
    1 |     1 | 2021-01-01 | 11:00:00 |         2 |           2
(4 rows)


 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   2 |    1 |     1 | 2021-01-01 | 10:00:00
   2 |    1 |     1 | 2021-01-01 | 11:00:00
   2 |    1 |     1 | 2021-01-01 | 12:00:00
   2 |    1 |     1 | 2021-01-01 | 13:00:00
   1 |    1 |     1 | 2021-01-01 | 10:00:00
   1 |    1 |     1 | 2021-01-01 | 11:00:00
   1 |    1 |     1 | 2021-01-01 | 12:00:00
   1 |    1 |     1 | 2021-01-01 | 13:00:00
   3 |    1 |     1 | 2021-01-01 | 10:00:00
   3 |    1 |     1 | 2021-01-01 | 12:00:00
(10 rows)


psql:integration_test_1.sql:622: NOTICE:  TRIGGER: Checking and removing rows that violate new capacity for room 1 floor 1
CALL
 room | floor |    date    |   time   | booker_id | approver_id
------+-------+------------+----------+-----------+-------------
    1 |     1 | 2021-01-01 | 13:00:00 |         2 |
    1 |     1 | 2021-01-01 | 11:00:00 |         2 |           2
(2 rows)


 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   2 |    1 |     1 | 2021-01-01 | 11:00:00
   2 |    1 |     1 | 2021-01-01 | 13:00:00
   1 |    1 |     1 | 2021-01-01 | 11:00:00
   1 |    1 |     1 | 2021-01-01 | 13:00:00
(4 rows)


ROLLBACK
*/
-- BEGIN;
--     -- SETUP
--     CALL add_department(1, 'firstDep');
--     CALL add_department(2, 'secondDep');
--     CALL add_room(1, 1, 'toBookRoom', 1, 3);
--     CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
--     CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);
--     CALL add_employee('third manager', '32345678', '32345678', '32345678', 'Manager', 2);

--     CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     CALL book_room(1, 1, '2021-1-1'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 2);
--     CALL book_room(1, 1, '2021-1-1'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
--     CALL book_room(1, 1, '2021-1-1'::DATE, '13:00:00'::TIME, '14:00:00'::TIME, 2);

--     CALL join_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     CALL join_meeting(1, 1, '2021-1-1'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 1);
--     CALL join_meeting(1, 1, '2021-1-1'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
--     CALL join_meeting(1, 1, '2021-1-1'::DATE, '13:00:00'::TIME, '14:00:00'::TIME, 1);
--     CALL join_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 3);
--     CALL join_meeting(1, 1, '2021-1-1'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 3);
--     CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     CALL approve_meeting(1, 1, '2021-1-1'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 2);

--     SELECT * FROM Bookings;
--     SELECT * FROM Participates;

--     -- CHANGE CAPACITY
--     CALL change_capacity(1, 1, 2, '2021-1-1'::DATE, 1);
--     SELECT * FROM Bookings;
--     SELECT * FROM Participates;
-- ROLLBACK;

-----------------------------
-- EMPLOYEE REMOVAL TESTS --
-----------------------------

-- TEST 10: Remove employee + bookings
/*
Test Case:
1. removed employee's non-approved future bookings removed
2. removed employee's approved future bookings removed
3. removed employee's non-approved past bookings preserved
4. removed employee's approved past bookings preserved
5. removed employee cannot create new bookings

EXPECTED:
BEGIN
CALL
CALL
CALL
CALL
psql:integration_test_1.sql:777: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-01, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:778: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-01, time 11:00:00 is within capacity
CALL
psql:integration_test_1.sql:779: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-02, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:780: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-02, time 11:00:00 is within capacity
CALL
CALL
CALL
 room | floor |    date    |   time   | booker_id | approver_id 
------+-------+------------+----------+-----------+-------------
    1 |     1 | 2021-02-01 | 11:00:00 |         2 |
    1 |     1 | 2021-02-02 | 11:00:00 |         2 |
    1 |     1 | 2021-02-01 | 10:00:00 |         2 |           1
    1 |     1 | 2021-02-02 | 10:00:00 |         2 |           1
(4 rows)


 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   2 |    1 |     1 | 2021-02-01 | 10:00:00
   2 |    1 |     1 | 2021-02-01 | 11:00:00
   2 |    1 |     1 | 2021-02-02 | 10:00:00
   2 |    1 |     1 | 2021-02-02 | 11:00:00
(4 rows)


psql:integration_test_1.sql:789: NOTICE:  TRIGGER: Update to employee 2, checking if resigned and removing future participations he made after 2021-02-01. Implicitly removing future approvals by deferred trigger.
psql:integration_test_1.sql:789: NOTICE:  TRIGGER: Booker 2 no longer participating in meeting on 2021-02-02, meeting removed.
psql:integration_test_1.sql:789: NOTICE:  TRIGGER: Booker 2 no longer participating in meeting on 2021-02-02, meeting removed.
CALL
 room | floor |    date    |   time   | booker_id | approver_id 
------+-------+------------+----------+-----------+-------------
    1 |     1 | 2021-02-01 | 11:00:00 |         2 |
    1 |     1 | 2021-02-01 | 10:00:00 |         2 |           1
(2 rows)


 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   2 |    1 |     1 | 2021-02-01 | 10:00:00
   2 |    1 |     1 | 2021-02-01 | 11:00:00
(2 rows)


psql:integration_test_1.sql:795: NOTICE:  TRIGGER: Booking cannot be made by employees who have resigned
psql:integration_test_1.sql:795: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-03, time 10:00:00 is within capacity
psql:integration_test_1.sql:795: NOTICE:  Employee 2: Booking at floor 1, room 1 on 2021-02-03 at 10:00:00 does not exist
CALL
 room | floor |    date    |   time   | booker_id | approver_id
------+-------+------------+----------+-----------+-------------
    1 |     1 | 2021-02-01 | 11:00:00 |         2 |
    1 |     1 | 2021-02-01 | 10:00:00 |         2 |           1
(2 rows)
*/ 
-- BEGIN;
--     -- SETUP
--     CALL add_department(1, 'firstDep');
--     CALL add_room(1, 1, 'toBookRoom', 1, 10);
--     CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
--     CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);

--     CALL book_room(1, 1, '2021-2-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     CALL book_room(1, 1, '2021-2-1'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 2);
--     CALL book_room(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     CALL book_room(1, 1, '2021-2-2'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 2);

--     CALL approve_meeting(1, 1, '2021-2-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     CALL approve_meeting(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);

--     SELECT * FROM Bookings;
--     SELECT * FROM Participates;

--     -- DELETE EMPLOYEE
--     CALL remove_employee(2, '2021-2-1');
--     SELECT * FROM Bookings;
--     SELECT * FROM Participates;


--     --Fail to make new bookings
--     CALL book_room(1, 1, '2021-2-3'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     SELECT * FROM Bookings;
-- ROLLBACK;

-- TEST 11: Remove employee + attendance
/*
Test Case:
1. removed employee's non-approved future attendance removed
2. removed employee's approved future attendance removed
3. removed employee's non-approved past attendance preserved
4. removed employee's approved past attendance preserved
5. removed employee cannot create new attendance

EXPECTED:
BEGIN
CALL
CALL
CALL
CALL
psql:integration_test_1.sql:819: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-01, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:820: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-01, time 11:00:00 is within capacity
CALL
psql:integration_test_1.sql:821: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-02, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:822: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-02, time 11:00:00 is within capacity
CALL
psql:integration_test_1.sql:823: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-02, time 12:00:00 is within capacity
CALL
psql:integration_test_1.sql:825: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-01, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:826: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-01, time 11:00:00 is within capacity
CALL
psql:integration_test_1.sql:827: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-02, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:828: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-02, time 11:00:00 is within capacity
CALL
CALL
CALL
 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   1 |    1 |     1 | 2021-02-01 | 10:00:00
   1 |    1 |     1 | 2021-02-01 | 11:00:00
   1 |    1 |     1 | 2021-02-02 | 10:00:00
   1 |    1 |     1 | 2021-02-02 | 11:00:00
   1 |    1 |     1 | 2021-02-02 | 12:00:00
   2 |    1 |     1 | 2021-02-01 | 10:00:00
   2 |    1 |     1 | 2021-02-01 | 11:00:00
   2 |    1 |     1 | 2021-02-02 | 10:00:00
   2 |    1 |     1 | 2021-02-02 | 11:00:00
(9 rows)


psql:integration_test_1.sql:836: NOTICE:  TRIGGER: Update to employee 2, checking if resigned and removing future participations he made after 2021-02-01. Implicitly removing future approvals by deferred trigger.
CALL
 eid | room | floor |    date    |   time   
-----+------+-------+------------+----------
   1 |    1 |     1 | 2021-02-01 | 10:00:00
   1 |    1 |     1 | 2021-02-01 | 11:00:00
   1 |    1 |     1 | 2021-02-02 | 10:00:00
   1 |    1 |     1 | 2021-02-02 | 11:00:00
   1 |    1 |     1 | 2021-02-02 | 12:00:00
   2 |    1 |     1 | 2021-02-01 | 10:00:00
   2 |    1 |     1 | 2021-02-01 | 11:00:00
(7 rows)


psql:integration_test_1.sql:840: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-02, time 12:00:00 is within capacity
psql:integration_test_1.sql:840: NOTICE:  TRIGGER: Booking cannot be joined by employees who have resigned
CALL
 eid | room | floor |    date    |   time   
-----+------+-------+------------+----------
   1 |    1 |     1 | 2021-02-01 | 10:00:00
   1 |    1 |     1 | 2021-02-01 | 11:00:00
   1 |    1 |     1 | 2021-02-02 | 10:00:00
   1 |    1 |     1 | 2021-02-02 | 11:00:00
   1 |    1 |     1 | 2021-02-02 | 12:00:00
   2 |    1 |     1 | 2021-02-01 | 10:00:00
   2 |    1 |     1 | 2021-02-01 | 11:00:00
(7 rows)



-- */
-- BEGIN;
--     -- SETUP
--     CALL add_department(1, 'firstDep');
--     CALL add_room(1, 1, 'toBookRoom', 1, 10);
--     CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
--     CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);

--     CALL book_room(1, 1, '2021-2-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     CALL book_room(1, 1, '2021-2-1'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 1);
--     CALL book_room(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     CALL book_room(1, 1, '2021-2-2'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 1);
--     CALL book_room(1, 1, '2021-2-2'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);

--     CALL join_meeting(1, 1, '2021-2-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     CALL join_meeting(1, 1, '2021-2-1'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 2);
--     CALL join_meeting(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     CALL join_meeting(1, 1, '2021-2-2'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 2);

--     CALL approve_meeting(1, 1, '2021-2-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     CALL approve_meeting(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);

--     SELECT * FROM Participates;

--     -- DELETE EMPLOYEE
--     CALL remove_employee(2, '2021-2-1');
--     SELECT * FROM Participates;

--     --Fail to make new attendance
--     CALL join_meeting(1, 1, '2021-2-2'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
--     SELECT * FROM Participates;
-- ROLLBACK;

-- TEST 12: Remove employee + approval
/*

Test Case:
1. removed employee's future approval removed
2. removed employee's past approval preserved
3. removed employee cannot create new approval

EXPECTED:
BEGIN
CALL
CALL
CALL
CALL
psql:integration_test_1.sql:960: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-01, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:961: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-02, time 10:00:00 is within capacity
CALL
psql:integration_test_1.sql:962: NOTICE:  TRIGGER: Checking if booking in room 1, floor 1, date 2021-02-02, time 11:00:00 is within capacity
CALL
CALL
CALL
 room | floor |    date    |   time   | booker_id | approver_id
------+-------+------------+----------+-----------+-------------
    1 |     1 | 2021-02-02 | 11:00:00 |         2 |
    1 |     1 | 2021-02-01 | 10:00:00 |         2 |           1
    1 |     1 | 2021-02-02 | 10:00:00 |         2 |           1
(3 rows)


psql:integration_test_1.sql:970: NOTICE:  TRIGGER: Update to employee 1, checking if resigned and removing future participations he made after 2021-02-01. Implicitly removing future approvals by deferred trigger.
CALL
 room | floor |    date    |   time   | booker_id | approver_id
------+-------+------------+----------+-----------+-------------
    1 |     1 | 2021-02-02 | 11:00:00 |         2 |
    1 |     1 | 2021-02-01 | 10:00:00 |         2 |           1
    1 |     1 | 2021-02-02 | 10:00:00 |         2 |           1
(3 rows)


psql:integration_test_1.sql:972: NOTICE:  TRIGGER (DEFERRED): Booking is not 
approved by manager, Booking deleted
COMMIT
BEGIN
 room | floor |    date    |   time   | booker_id | approver_id
------+-------+------------+----------+-----------+-------------
    1 |     1 | 2021-02-01 | 10:00:00 |         2 |           1
    1 |     1 | 2021-02-02 | 10:00:00 |         2 |           1
(2 rows)


psql:integration_test_1.sql:979: ERROR:  Manager is Resigned or does not exist
CONTEXT:  PL/pgSQL function approve_meeting(integer,integer,date,time without time zone,time without time zone,integer) line 33 at RAISE
*/
BEGIN;
    -- SETUP
    CALL add_department(1, 'firstDep');
    CALL add_room(1, 1, 'toBookRoom', 1, 10);
    CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
    CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);

    CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
    CALL book_room(1, 1, '2021-2-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
    CALL book_room(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
    CALL book_room(1, 1, '2021-2-2'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 2);

    CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
    CALL approve_meeting(1, 1, '2021-2-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
    CALL approve_meeting(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);

    SELECT * FROM Bookings;

    -- DELETE EMPLOYEE
    CALL remove_employee(1, '2021-2-1');
    SELECT * FROM Bookings; -- approvals will not be deleted before COMMIT due to deferred trigger
ROLLBACK;
SELECT * FROM Bookings;

-- BEGIN;
--     SELECT * FROM Bookings; -- approvals will be deleted after COMMIT

--     --Fail to make new approval
--     CALL approve_meeting(1, 1, '2021-2-2'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 1);
-- ROLLBACK;
