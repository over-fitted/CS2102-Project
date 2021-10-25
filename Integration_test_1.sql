<<<<<<< Updated upstream
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
=======
-- TEST Fever Event and Close Contact --
/* 
TEST CASES:
1) Fever Event Detected
2) Contact_tracing Function returns appropriate table
3) If an employee has fever they are removed from all future meetings and their bookings are canceled, same for close contact personel
4) Ensure an employee with fever can book a room or participate in a meeting  

EXPECTED:
1) Raise Notice for Employee with fever
2) Close Contact Table is accurate
3) Relevent removal of bookings and participants from meetings


*/
\i schema.sql
\i proc.sql

--Test1
-- Booker Declaring Fever & Close Contact
/*
Bookings Table
 room | floor |    date    |   time   | booker_id | approver_id
------+-------+------------+----------+-----------+-------------
    1 |     1 | 2021-01-01 | 00:00:00 |         1 |           1
    3 |     3 | 2021-01-01 | 05:00:00 |         4 |           1
    4 |     4 | 2021-01-01 | 03:00:00 |         8 |           1
    5 |     5 | 2021-01-04 | 00:00:00 |         7 |           1
    6 |     6 | 2021-01-02 | 00:00:00 |         7 |           1
    8 |     8 | 2021-01-04 | 03:00:00 |         7 |
(6 rows)

Participates
 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   1 |    1 |     1 | 2021-01-01 | 00:00:00
   3 |    1 |     1 | 2021-01-01 | 00:00:00
   4 |    1 |     1 | 2021-01-01 | 00:00:00
   5 |    1 |     1 | 2021-01-01 | 00:00:00
   6 |    1 |     1 | 2021-01-01 | 00:00:00
   4 |    3 |     3 | 2021-01-01 | 05:00:00
   8 |    4 |     4 | 2021-01-01 | 03:00:00
   5 |    4 |     4 | 2021-01-01 | 03:00:00
   7 |    5 |     5 | 2021-01-04 | 00:00:00
   7 |    6 |     6 | 2021-01-02 | 00:00:00
   8 |    6 |     6 | 2021-01-02 | 00:00:00
   9 |    6 |     6 | 2021-01-02 | 00:00:00
   7 |    8 |     8 | 2021-01-04 | 03:00:00
*/

/*
BEGIN;
-- Add Departments
CALL add_department (0, 'Human Resources');

-- Create Rooms (Fever_Room will contain personel with fever)
CALL add_room(1, 1, 'Room_1', 0, 13);
CALL add_room(2, 2, 'Room_2', 0, 14);
CALL add_room(3, 3, 'Room_3', 0, 5);
CALL add_room(4, 4, 'Room_4', 0, 9);
CALL add_room(5, 5, 'Room_5', 0, 16);
CALL add_room(6, 6, 'Room_6', 0, 6);
CALL add_room(7, 7, 'Room_7', 0, 6);
CALL add_room(8, 8, 'Room_8', 0, 10);

-- Create Employees (Will contain employees which will declare temperature above or below 37.5)

--Fever employees
CALL add_employee('Fever_1', NULL, NULL, '84399505', 'Manager', 0); -- Employee Id 1
CALL add_employee('Fever_2', NULL, NULL, '39630089', 'Senior', 0); -- Employee Id 2

--Close contact employees
CALL add_employee('Close_contact_1', NULL, NULL, '51244095', 'Senior', 0); -- Employee Id 3
CALL add_employee('Close_contact_2', NULL, NULL, '87467446', 'Senior', 0); -- Employee Id 4
CALL add_employee('Close_contact_3', NULL, NULL, '12314552', 'Senior', 0); -- Employee Id 5
CALL add_employee('Close_contact_4', NULL, NULL, '83413546', 'Senior', 0); -- Employee Id 6

CALL add_employee('Non_Fever_1', NULL, NULL, '47534732', 'Senior', 0); -- Employee Id 7
CALL add_employee('Non_Fever_2', NULL, NULL, '47534732', 'Senior', 0); -- Employee Id 8
CALL add_employee('Non_Fever_3', NULL, NULL, '47534732', 'Senior', 0); -- Employee Id 9

-- Rooms being booked

--Booker will declare fever and is a past booking, booking will stay
CALL book_room(1, 1,'2021-01-01', '00:00:00', '01:00:00', 1);
CALL join_meeting(1, 1,'2021-01-01', '00:00:00', '01:00:00', 3);
CALL join_meeting(1, 1,'2021-01-01', '00:00:00', '01:00:00', 4);
CALL join_meeting(1, 1,'2021-01-01', '00:00:00', '01:00:00', 5);
CALL join_meeting(1, 1,'2021-01-01', '00:00:00', '01:00:00', 6);

--Booker has future meeting should be deleted
CALL book_room(7, 7,'2021-01-03', '10:00:00', '11:00:00', 1);

-- Employee 3 has a booking of his own in the future should be deleted
CALL book_room(2, 2,'2021-01-03', '00:00:00', '02:00:00', 3);

-- Employee 4 in booked a past meeting, no change
CALL book_room(3, 3,'2021-01-01', '05:00:00', '06:00:00', 4);

-- Employee 5 is a particpant in a past meeting, no change
CALL book_room(4, 4,'2021-01-01', '03:00:00', '04:00:00', 8);
CALL join_meeting(4, 4,'2021-01-01', '03:00:00', '04:00:00', 5);

--Employee 6 is a participant in a future meeting, but is not the booker : removed from Booking
CALL book_room(5, 5,'2021-01-04', '00:00:00', '01:00:00', 7);
CALL join_meeting(5, 5,'2021-01-04', '00:00:00', '01:00:00', 6);

--Booking should not change
CALL book_room(6, 6,'2021-01-02', '00:00:00', '01:00:00', 7);
CALL join_meeting(6, 6,'2021-01-02', '00:00:00', '01:00:00', 8);
CALL join_meeting(6, 6,'2021-01-02', '00:00:00', '01:00:00', 9);

CALL approve_meeting(1, 1,'2021-01-01', '00:00:00', '01:00:00', 1);
CALL approve_meeting(2, 2,'2021-01-03', '00:00:00', '02:00:00', 1);
CALL approve_meeting(3, 3,'2021-01-01', '05:00:00', '06:00:00', 1);
CALL approve_meeting(4, 4,'2021-01-01', '03:00:00', '04:00:00', 1);
CALL approve_meeting(5, 5,'2021-01-04', '00:00:00', '01:00:00', 1);
CALL approve_meeting(6, 6,'2021-01-02', '00:00:00', '01:00:00', 1);
CALL approve_meeting(7, 7,'2021-01-03', '10:00:00', '11:00:00', 1);

--Employee 1 declare after 1 day
CALL declare_health(1, '2021-01-02', 37.9, '02:00:00');


-- Employee with fever trying to Making a booking
CALL book_room(8, 8,'2021-01-01', '00:00:00', '01:00:00', 1);


-- Employee with fever tries to participate in meeting
CALL book_room(8, 8,'2021-01-04', '03:00:00', '04:00:00', 7);
CALL join_meeting(8, 8,'2021-01-04', '03:00:00', '04:00:00', 1);

SELECT * FROM Bookings;

SELECT * FROM Participates;

ROLLBACK;
*/


--Test2
--Participant Declaring Fever
/*
 room | floor |    date    |   time   | booker_id | approver_id
------+-------+------------+----------+-----------+-------------
    1 |     1 | 2021-01-01 | 00:00:00 |         1 |           1
    5 |     5 | 2021-01-04 | 00:00:00 |         7 |           1
    6 |     6 | 2021-01-02 | 00:00:00 |         7 |           1
(3 rows)


 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   1 |    1 |     1 | 2021-01-01 | 00:00:00
   6 |    1 |     1 | 2021-01-01 | 00:00:00
   7 |    5 |     5 | 2021-01-04 | 00:00:00
   7 |    6 |     6 | 2021-01-02 | 00:00:00
   8 |    6 |     6 | 2021-01-02 | 00:00:00
   9 |    6 |     6 | 2021-01-02 | 00:00:00
(6 rows)
>>>>>>> Stashed changes
*/

/*
BEGIN;
<<<<<<< Updated upstream
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
=======
-- Add Departments
CALL add_department (0, 'Human Resources');

-- Create Rooms (Fever_Room will contain personel with fever)
CALL add_room(1, 1, 'Room_1', 0, 13);
CALL add_room(2, 2, 'Room_2', 0, 14);
CALL add_room(3, 3, 'Room_3', 0, 5);
CALL add_room(4, 4, 'Room_4', 0, 9);
CALL add_room(5, 5, 'Room_5', 0, 16);
CALL add_room(6, 6, 'Room_6', 0, 6);
CALL add_room(7, 7, 'Room_7', 0, 6);
CALL add_room(8, 8, 'Room_8', 0, 10);

-- Create Employees (Will contain employees which will declare temperature above or below 37.5)

--Fever employees
CALL add_employee('Fever_1', NULL, NULL, '84399505', 'Manager', 0); -- Employee Id 1
CALL add_employee('Fever_2', NULL, NULL, '39630089', 'Senior', 0); -- Employee Id 2

--Close contact employees
CALL add_employee('Close_contact_1', NULL, NULL, '51244095', 'Senior', 0); -- Employee Id 3
CALL add_employee('Close_contact_2', NULL, NULL, '87467446', 'Senior', 0); -- Employee Id 4
CALL add_employee('Close_contact_3', NULL, NULL, '12314552', 'Senior', 0); -- Employee Id 5
CALL add_employee('Close_contact_4', NULL, NULL, '83413546', 'Senior', 0); -- Employee Id 6

CALL add_employee('Non_Fever_1', NULL, NULL, '47534732', 'Senior', 0); -- Employee Id 7
CALL add_employee('Non_Fever_2', NULL, NULL, '47534732', 'Senior', 0); -- Employee Id 8
CALL add_employee('Non_Fever_3', NULL, NULL, '47534732', 'Senior', 0); -- Employee Id 9

-- Rooms being booked

--Employee 6 is a participant in a past meeting, no change
CALL book_room(1, 1,'2021-01-01', '00:00:00', '01:00:00', 1);
CALL join_meeting(1, 1,'2021-01-01', '00:00:00', '01:00:00', 2);

--Employee 6 is a participant in a future meeting, but is not the booker : removed from Booking
CALL book_room(5, 5,'2021-01-04', '00:00:00', '01:00:00', 7);
CALL join_meeting(5, 5,'2021-01-04', '00:00:00', '01:00:00', 2);


--Close contact meeting should be removed
CALL book_room(1, 1,'2021-01-05', '00:00:00', '01:00:00', 1);

--Booking should not change
CALL book_room(6, 6,'2021-01-02', '00:00:00', '01:00:00', 7);
CALL join_meeting(6, 6,'2021-01-02', '00:00:00', '01:00:00', 8);
CALL join_meeting(6, 6,'2021-01-02', '00:00:00', '01:00:00', 9);

CALL approve_meeting(1, 1,'2021-01-01', '00:00:00', '01:00:00', 1);
CALL approve_meeting(5, 5,'2021-01-04', '00:00:00', '01:00:00', 1);
CALL approve_meeting(6, 6,'2021-01-02', '00:00:00', '01:00:00', 1);

--Employee 6 declare after 1 day
CALL declare_health(2, '2021-01-02', 37.9, '02:00:00');

SELECT * FROM Bookings;

SELECT * FROM Participates;

ROLLBACK;
*/


--Test3
--Data Edge cases Test
/*
 room | floor |    date    |   time   | booker_id | approver_id
------+-------+------------+----------+-----------+-------------
    1 |     1 | 2021-01-07 | 00:00:00 |         1 |           1
    3 |     3 | 2021-01-20 | 00:00:00 |         3 |           1
    4 |     4 | 2021-01-01 | 00:00:00 |         4 |           1
    6 |     6 | 2021-01-02 | 00:00:00 |         7 |           1
    7 |     7 | 2021-01-17 | 01:00:00 |         4 |           1
    8 |     8 | 2021-01-21 | 00:00:00 |         4 |           1
(6 rows)


 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   1 |    1 |     1 | 2021-01-07 | 00:00:00
   2 |    1 |     1 | 2021-01-07 | 00:00:00
   7 |    1 |     1 | 2021-01-07 | 00:00:00
   3 |    1 |     1 | 2021-01-07 | 00:00:00
   4 |    7 |     7 | 2021-01-17 | 01:00:00
   3 |    3 |     3 | 2021-01-20 | 00:00:00
   4 |    8 |     8 | 2021-01-21 | 00:00:00
   3 |    8 |     8 | 2021-01-21 | 00:00:00
   4 |    4 |     4 | 2021-01-01 | 00:00:00
   5 |    4 |     4 | 2021-01-01 | 00:00:00
   6 |    4 |     4 | 2021-01-01 | 00:00:00
   7 |    6 |     6 | 2021-01-02 | 00:00:00
   8 |    6 |     6 | 2021-01-02 | 00:00:00
   9 |    6 |     6 | 2021-01-02 | 00:00:00
(14 rows)
*/
BEGIN;
-- Add Departments
CALL add_department (0, 'Human Resources');

-- Create Rooms (Fever_Room will contain personel with fever)
CALL add_room(1, 1, 'Room_1', 0, 13);
CALL add_room(2, 2, 'Room_2', 0, 14);
CALL add_room(3, 3, 'Room_3', 0, 5);
CALL add_room(4, 4, 'Room_4', 0, 9);
CALL add_room(5, 5, 'Room_5', 0, 16);
CALL add_room(6, 6, 'Room_6', 0, 6);
CALL add_room(7, 7, 'Room_7', 0, 6);
CALL add_room(8, 8, 'Room_8', 0, 10);

-- Create Employees (Will contain employees which will declare temperature above or below 37.5)

--Fever employees
CALL add_employee('Fever_1', NULL, NULL, '84399505', 'Manager', 0); -- Employee Id 1
CALL add_employee('Fever_2', NULL, NULL, '39630089', 'Senior', 0); -- Employee Id 2

--Close contact employees
CALL add_employee('Close_contact_1', NULL, NULL, '51244095', 'Senior', 0); -- Employee Id 3
CALL add_employee('Close_contact_2', NULL, NULL, '87467446', 'Senior', 0); -- Employee Id 4
CALL add_employee('Close_contact_3', NULL, NULL, '12314552', 'Senior', 0); -- Employee Id 5
CALL add_employee('Close_contact_4', NULL, NULL, '83413546', 'Senior', 0); -- Employee Id 6

CALL add_employee('Non_Fever_1', NULL, NULL, '47534732', 'Senior', 0); -- Employee Id 7
CALL add_employee('Non_Fever_2', NULL, NULL, '47534732', 'Senior', 0); -- Employee Id 8
CALL add_employee('Non_Fever_3', NULL, NULL, '47534732', 'Senior', 0); -- Employee Id 9

-- Rooms being booked

--Employee 2,3,7 is a close contact because the meeting was 3 days ago
CALL book_room(1, 1,'2021-01-07', '00:00:00', '01:00:00', 1);
CALL join_meeting(1, 1,'2021-01-07', '00:00:00', '01:00:00', 2);
CALL join_meeting(1, 1,'2021-01-07', '00:00:00', '01:00:00', 7);
CALL join_meeting(1, 1,'2021-01-07', '00:00:00', '01:00:00', 3);

--Employee 7 is a close contact thus the meeting should be deleted
CALL book_room(5, 5,'2021-01-17', '00:00:00', '01:00:00', 7);
CALL join_meeting(5, 5,'2021-01-17', '00:00:00', '01:00:00', 2);

--Employee 7 should be removed from this meeting
CALL book_room(7, 7,'2021-01-17', '01:00:00', '02:00:00', 4);
CALL join_meeting(5, 5,'2021-01-17', '01:00:00', '02:00:00', 7);

--Employee 3 is a close contact but meeting is after 7 days, should not be deleted
CALL book_room(3, 3,'2021-01-20', '00:00:00', '01:00:00', 3);

--Employee 3 is a close contact and meeting is after 7 days
CALL book_room(8, 8,'2021-01-21', '00:00:00', '01:00:00', 4);
CALL join_meeting(8, 8,'2021-01-21', '00:00:00', '01:00:00', 3);

--Employee 4,5,6 should not be close contact emlpoyees as meeting was more than 3 days ago
CALL book_room(4, 4,'2021-01-01', '00:00:00', '01:00:00', 4);
CALL join_meeting(4, 4,'2021-01-01', '00:00:00', '01:00:00', 5);
CALL join_meeting(4, 4,'2021-01-01', '00:00:00', '01:00:00', 6);

--Booking should not change
CALL book_room(6, 6,'2021-01-02', '00:00:00', '01:00:00', 7);
CALL join_meeting(6, 6,'2021-01-02', '00:00:00', '01:00:00', 8);
CALL join_meeting(6, 6,'2021-01-02', '00:00:00', '01:00:00', 9);

CALL approve_meeting(1, 1,'2021-01-07', '00:00:00', '01:00:00', 1);
CALL approve_meeting(3, 3,'2021-01-20', '00:00:00', '01:00:00', 1);
CALL approve_meeting(4, 4,'2021-01-01', '00:00:00', '01:00:00', 1);
CALL approve_meeting(5, 5,'2021-01-17', '00:00:00', '01:00:00', 1);
CALL approve_meeting(6, 6,'2021-01-02', '00:00:00', '01:00:00', 1);
CALL approve_meeting(7, 7,'2021-01-17', '01:00:00', '02:00:00', 1);
CALL approve_meeting(8, 8,'2021-01-21', '00:00:00', '01:00:00', 1);

--Employee 6 declare after 1 day
CALL declare_health(1, '2021-01-10', 37.9, '01:00:00');

SELECT * FROM Bookings;

SELECT * FROM Participates;

ROLLBACK;
>>>>>>> Stashed changes
