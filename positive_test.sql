\i schema.sql
\i proc.sql
    
--
-- DEFAULT BEHAVIOUR
--

-- SETUP
-- 1) Add 2 departments
BEGIN;
CALL add_department(1, 'firstDep');
CALL add_department(2, 'secondDep');

-- Shows that department adding works as expected
SELECT * FROM Departments;

-- 2) Add 4 persons, 1 per type per department
CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
CALL add_employee('second senior', null, '22345678', null, 'Senior', 1);
CALL add_employee('third junior', null, null, '32345678', 'Junior', 1);
CALL add_employee('fourth junior', '42345678', null, null, 'Junior', 1);

-- Shows non-mobile numbers can be non-unique
CALL add_employee('d2first manager', '12345678', '13345678', '13345678', 'Manager', 2);
CALL add_employee('d2second senior', '23345678', '23345678', '12345678', 'Senior', 2);

CALL add_employee('d2third junior', '33345678', '33345678', '33345678', 'Junior', 2);
CALL add_employee('d2fourth junior', '43345678', '43345678', '43345678', 'Junior', 2);
SELECT * FROM Employees;

-- 3) 1 room per department, shows that both add rooms and default search room behaviour are as expected
CALL add_room(1, 1, 'toBookRoom', 1, 3);
CALL add_room(2, 2, 'dummyRoom', 1, 10);
SELECT * FROM search_room(3, '2021-1-1', '10:00:00'::TIME, '12:00:00'::TIME);
SELECT * FROM search_room(9, '2021-1-1', '10:00:00'::TIME, '12:00:00'::TIME);

-- 4) Attempt to book with each person on department 1 room
CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
CALL book_room(1, 1, '2021-2-1'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 2);
CALL book_room(1, 1, '2021-1-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 5);
CALL book_room(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 6);

SELECT * FROM Bookings;

-- Post-booking available rooms
SELECT * FROM search_room(10, '2021-1-1', '10:00:00', '13:00:00');

-- 5) Check manager report for both managers. This shows that book_room and manager report behaviour are consistent with expectations
/*
a) each manager can only view the bookings of employees from their own department
b) start-date inclusive
*/
SELECT * FROM view_manager_report('2021-1-1', 1);
SELECT * FROM view_manager_report('2021-2-1', 1);
SELECT * FROM view_manager_report('2021-1-1', 5);

-- 6) everyone joins 1 booking to show capacity check
CALL join_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
CALL join_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 3);
CALL join_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 4);
CALL join_meeting(1, 1, '2021-1-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
CALL join_meeting(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);

-- view future meeting doesnt show non-approved participation
SELECT * FROM view_future_meeting('2021-1-1', 1);

-- 7) Have manager from department 1 approve bookings for own and other departments
CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
CALL approve_meeting(1, 1, '2021-1-2'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 1);

-- view future meeting shows non-approved participation, so 2 people removed
SELECT * FROM view_future_meeting('2021-1-1', 1);

-- approved bookings no longer appear in the report
SELECT * FROM view_manager_report('2021-1-1', 1);
SELECT * FROM view_manager_report('2021-1-1', 5);

-- unapproved meeting is cancelled and all participants are booted when organiser leaves
SELECT * FROM participates;
CALL leave_meeting(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 6);
SELECT * FROM participates;

-- Post-approval available rooms
SELECT * FROM search_room(10, '2021-1-1', '10:00:00', '13:00:00');
ROLLBACK;

--
-- RESIGNATION 
--
/*
RESIGNEDCANNOTBOOK + REMOVERESIGNEDRECORDS
Test Case:
1. removed employee's non-approved future bookings removed
2. removed employee's approved future bookings removed
3. removed employee's non-approved past bookings preserved
4. removed employee's approved past bookings preserved
5. removed employee cannot create new bookings
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

/*
RESIGNCANNOTJOIN
Test Case:
1. removed employee's non-approved future attendance removed
2. removed employee's approved future attendance removed
3. removed employee's non-approved past attendance preserved
4. removed employee's approved past attendance preserved
5. removed employee cannot create new attendance
*/
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
-- -- REMOVERESIGNEDRECORDS
-- Test Case:
-- 1. removed employee's future approval removed
-- 2. removed employee's past approval preserved
-- 3. removed employee cannot create new approval

-- BEGIN;
--     -- SETUP
--     CALL add_department(1, 'firstDep');
--     CALL add_room(1, 1, 'toBookRoom', 1, 10);
--     CALL add_employee('first manager', '12345678', '12345678', '12345678', 'Manager', 1);
--     CALL add_employee('second senior', '22345678', '22345678', '22345678', 'Senior', 1);

--     CALL book_room(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     CALL book_room(1, 1, '2021-2-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     CALL book_room(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
--     CALL book_room(1, 1, '2021-2-2'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 2);

--     CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     CALL approve_meeting(1, 1, '2021-2-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
--     CALL approve_meeting(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);

--     SELECT * FROM Bookings;

--     -- DELETE EMPLOYEE
--     CALL remove_employee(1, '2021-2-1');
--     SELECT * FROM Bookings; -- approvals will not be deleted before COMMIT due to deferred trigger
-- ROLLBACK;
-- SELECT * FROM Bookings;

--
-- FEVER
-- VERSION 2
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
(13 rows)
*/


BEGIN;
-- Add Departments
CALL add_department (0, 'Human Resources');

-- Create Rooms (Fever_Room will contain personel with fever)
CALL add_room(1, 1, 'FEVER_ROOM', 0, 13);
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

SELECT * FROM Bookings;
SELECT * FROM participates;

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
