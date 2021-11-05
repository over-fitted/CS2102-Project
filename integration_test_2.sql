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
(13 rows)
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
   2 |    1 |     1 | 2021-01-01 | 00:00:00
   7 |    5 |     5 | 2021-01-04 | 00:00:00
   7 |    6 |     6 | 2021-01-02 | 00:00:00
   8 |    6 |     6 | 2021-01-02 | 00:00:00
   9 |    6 |     6 | 2021-01-02 | 00:00:00
(6 rows)
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

--Employee 6 is a participant in a past meeting, no change
CALL book_room(1, 1,'2021-01-01', '00:00:00', '01:00:00', 1);
CALL join_meeting(1, 1,'2021-01-01', '00:00:00', '01:00:00', 2);

--Employee 2 is a participant in a future meeting, but is not the booker : removed from Booking
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
--Date Edge cases Test
/*
 room | floor |    date    |   time   | booker_id | approver_id
------+-------+------------+----------+-----------+-------------
    5 |     5 | 2021-01-09 | 00:00:00 |         7 |
    1 |     1 | 2021-01-07 | 00:00:00 |         1 |           1
    3 |     3 | 2021-01-20 | 00:00:00 |         3 |           1
    4 |     4 | 2021-01-01 | 00:00:00 |         4 |           1
    6 |     6 | 2021-01-02 | 00:00:00 |         7 |           1
    7 |     7 | 2021-01-17 | 01:00:00 |         4 |           1
    8 |     8 | 2021-01-21 | 00:00:00 |         4 |           1
(7 rows)


 eid | room | floor |    date    |   time
-----+------+-------+------------+----------
   1 |    1 |     1 | 2021-01-07 | 00:00:00
   2 |    1 |     1 | 2021-01-07 | 00:00:00
   7 |    1 |     1 | 2021-01-07 | 00:00:00
   3 |    1 |     1 | 2021-01-07 | 00:00:00
   4 |    7 |     7 | 2021-01-17 | 01:00:00
   7 |    5 |     5 | 2021-01-09 | 00:00:00
   9 |    5 |     5 | 2021-01-09 | 00:00:00
   3 |    3 |     3 | 2021-01-20 | 00:00:00
   4 |    8 |     8 | 2021-01-21 | 00:00:00
   3 |    8 |     8 | 2021-01-21 | 00:00:00
   4 |    4 |     4 | 2021-01-01 | 00:00:00
   5 |    4 |     4 | 2021-01-01 | 00:00:00
   6 |    4 |     4 | 2021-01-01 | 00:00:00
   7 |    6 |     6 | 2021-01-02 | 00:00:00
   8 |    6 |     6 | 2021-01-02 | 00:00:00
   9 |    6 |     6 | 2021-01-02 | 00:00:00
(16 rows)
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

--Employee 7 booked a room but it has not been approved, Thus 9 should not appear in close contacts
CALL book_room(5, 5,'2021-01-9', '00:00:00', '01:00:00', 7);
CALL join_meeting(5, 5,'2021-01-9', '00:00:00', '01:00:00', 9);

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

--Employee 1 declaring fever
CALL declare_health(1, '2021-01-10', 37.9, '01:00:00');

SELECT * FROM Bookings;

SELECT * FROM Participates;

ROLLBACK;
*/

--Test4
--Non Compliance test (Need to load data.sql for this test)
/*
 employeeid | numdays
------------+---------
         40 |       3
          3 |       3
          5 |       3
         42 |       3
         43 |       3
         44 |       3
         46 |       3
         47 |       3
         48 |       3
         49 |       3
         50 |       3
          9 |       3
         10 |       3
         12 |       3
         14 |       3
         17 |       3
         18 |       3
         19 |       3
         20 |       3
         22 |       3
         24 |       3
         25 |       3
         26 |       3
         27 |       3
         28 |       3
         29 |       3
         30 |       3
         31 |       3
         32 |       3
         33 |       3
         34 |       3
         36 |       3
         37 |       3
         38 |       3
         39 |       3
          2 |       3
         41 |       3
         16 |       2
         21 |       2
         35 |       2
         45 |       2
          8 |       2
         23 |       2
         11 |       1
         15 |       1
(45 rows)
*/
/*
BEGIN;

CALL declare_health(1, '2021-01-02', 36.9, '02:00:00');
CALL declare_health(4, '2021-01-02', 35.9, '02:00:00');
CALL declare_health(6, '2021-01-02', 36.9, '02:00:00');
CALL declare_health(7, '2021-01-02', 34.9, '02:00:00');
CALL declare_health(13, '2021-01-02', 35.9, '02:00:00');
CALL declare_health(15, '2021-01-02', 34.9, '02:00:00');
CALL declare_health(11, '2021-01-02', 36.2, '02:00:00');
CALL declare_health(8, '2021-01-02', 37.2, '02:00:00');
CALL declare_health(45, '2021-01-02', 34.3, '02:00:00');
CALL declare_health(35, '2021-01-02', 35.4, '02:00:00');
CALL declare_health(16, '2021-01-02', 34.5, '02:00:00');
CALL declare_health(23, '2021-01-02', 35.1, '02:00:00');
CALL declare_health(21, '2021-01-02', 34.6, '02:00:00');

CALL declare_health(1, '2021-01-03', 36.9, '02:00:00');
CALL declare_health(4, '2021-01-03', 35.9, '02:00:00');
CALL declare_health(6, '2021-01-03', 36.9, '02:00:00');
CALL declare_health(7, '2021-01-03', 34.9, '02:00:00');
CALL declare_health(13, '2021-01-03', 35.9, '02:00:00');
CALL declare_health(15, '2021-01-03', 34.9, '02:00:00');
CALL declare_health(11, '2021-01-03', 36.2, '02:00:00');


CALL declare_health(1, '2021-01-04', 36.9, '02:00:00');
CALL declare_health(4, '2021-01-04', 35.9, '02:00:00');
CALL declare_health(6, '2021-01-04', 36.9, '02:00:00');
CALL declare_health(7, '2021-01-04', 34.9, '02:00:00');
CALL declare_health(13, '2021-01-04', 35.9, '02:00:00');

SELECT * FROM non_compliance('2021-01-02', '2021-01-04');

ROLLBACK;
*/