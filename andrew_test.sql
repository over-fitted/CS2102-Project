\i 'schema.sql'
\i 'proc.sql'

-- TEST ADMIN 2 view_booking_report --
/* 
TEST CASES:
1) sorted by date and time correctly (3 out of order inserted)
2) show isapproved differently
3) do not show past bookings

EXPECTED:
1) sorted by date and time
2) should not show Oct 22 entry
3) only 30th oct approved

 floor | room |    date    | starttime | isapproved
-------+------+------------+-----------+------------
     1 |    1 | 2021-10-29 | 14:00:00  | f
     1 |    1 | 2021-10-30 | 14:00:00  | f
     1 |    1 | 2021-10-30 | 13:00:00  | t
*/
BEGIN;
INSERT INTO Departments VALUES (1, 'firstDep');
INSERT INTO MeetingRooms VALUES (1,1,'firstRoom',1, '2021-10-22', 5);
INSERT INTO Employees VALUES (1,'first guy', 'first@mail.com', 'Manager', 1, null, 92436283);
INSERT INTO Bookings VALUES (1, 1, '2021-10-22', '14:00:00', 1);
INSERT INTO Bookings VALUES (1, 1, '2021-10-30', '14:00:00', 1);
INSERT INTO Bookings VALUES (1, 1, '2021-10-29', '14:00:00', 1);
INSERT INTO Bookings VALUES (1, 1, '2021-10-30', '13:00:00', 1, 1);

SELECT * FROM view_booking_report('2021-10-22', 1);
ROLLBACK;

-- TEST AD
/*
TEST CASES:
1) sorted by date and time correctly (3 out of order inserted)
2) do not show non-approved ('2021-10-30', '13:00:00')
3) do not show past bookings
4) do not show non-participating ('2021-11-29', '14:00:00')

EXPECTED:
 floor | room |    date    | starttime | eid
-------+------+------------+-----------+-----
     1 |    1 | 2021-10-29 | 14:00:00  |   1
     1 |    1 | 2021-10-29 | 15:00:00  |   1
     1 |    1 | 2021-10-30 | 14:00:00  |   1
(3 rows)


 floor | room | date | starttime | eid
-------+------+------+-----------+-----
(0 rows)
*/
BEGIN;
INSERT INTO Departments VALUES (1, 'firstDep');
INSERT INTO MeetingRooms VALUES (1,1,'firstRoom',1, '2021-10-22', 5);
INSERT INTO Employees VALUES (1,'first guy', 'first@mail.com', 'Manager', 1, null, 92436283);
INSERT INTO Employees VALUES (2,'second guy', '2nd@mail.com', 'Junior', 1, null, 91234567);
INSERT INTO Bookings VALUES (1, 1, '2021-10-22', '14:00:00', 1, 1);
INSERT INTO Bookings VALUES (1, 1, '2021-10-30', '14:00:00', 1, 1);
INSERT INTO Bookings VALUES (1, 1, '2021-10-29', '15:00:00', 1, 1);
INSERT INTO Bookings VALUES (1, 1, '2021-10-29', '14:00:00', 1, 1);
INSERT INTO Bookings VALUES (1, 1, '2021-11-29', '14:00:00', 1, 1);
INSERT INTO Bookings VALUES (1, 1, '2021-10-30', '13:00:00', 1);
INSERT INTO Participates VALUES (1, 1, 1, '2021-10-22', '14:00:00');
INSERT INTO Participates VALUES (1, 1, 1, '2021-10-30', '14:00:00');
INSERT INTO Participates VALUES (1, 1, 1, '2021-10-29', '15:00:00');
INSERT INTO Participates VALUES (1, 1, 1, '2021-10-29', '14:00:00');
INSERT INTO Participates VALUES (1, 1, 1, '2021-10-30', '13:00:00');

SELECT * FROM view_future_meeting('2021-10-22', 1);
SELECT * FROM view_future_meeting('2021-10-22', 2);
ROLLBACK;

-- TEST ADMIN 4
/*
TEST CASES:
1) show rooms that require approval
    a) sort date
    b) sort time
2) do not show rooms that are approved done
3) do not show rooms that are booked by other departments done
4) do not show anything for non-managers 
5) do not show past bookings 

EXPECTED:
 floor | room | date | starttime | eid
-------+------+------+-----------+-----
(0 rows)


 floor | room |    date    | starttime | eid
-------+------+------------+-----------+-----
     1 |    2 | 2021-10-22 | 14:00:00  |   2
     1 |    2 | 2021-10-22 | 15:00:00  |   2
     1 |    2 | 2021-10-30 | 13:00:00  |   2
(3 rows)
*/
BEGIN;
INSERT INTO Departments VALUES (1, 'firstDep');
INSERT INTO Departments VALUES (2, '2ndDep');
INSERT INTO MeetingRooms VALUES (1, 1,'firstRoom', 1, '2021-10-22', 5);
INSERT INTO MeetingRooms VALUES (1, 2, '2ndRoom', 1, '2021-10-22', 5);
INSERT INTO Employees VALUES (1,'first guy', 'first@mail.com', 'Manager', 1, null, 92436283);
INSERT INTO Employees VALUES (2,'second guy', '2nd@mail.com', 'Senior', 1, null, 91234567);
INSERT INTO Employees VALUES (3,'second guy', '2nd@mail.com', 'Senior', 2, null, 91324567);
INSERT INTO Bookings VALUES (1, 1, '2021-10-30', '15:00:00', 1, 1); -- approved
INSERT INTO Bookings VALUES (1, 1, '2021-10-30', '14:00:00', 3); -- wrong department
INSERT INTO Bookings VALUES (2, 1, '2020-10-21', '14:00:00', 2); -- outdated

INSERT INTO Bookings VALUES (2, 1, '2021-10-30', '13:00:00', 2); -- later date
INSERT INTO Bookings VALUES (2, 1, '2021-10-22', '15:00:00', 2); -- later time same date
INSERT INTO Bookings VALUES (2, 1, '2021-10-22', '14:00:00', 2);
SELECT * FROM view_manager_report('2021-10-22', 2); -- not manager
SELECT * FROM view_manager_report('2021-10-22', 1); 
ROLLBACK;