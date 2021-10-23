-- TEST ADMIN 2 view_booking_report --
/* EXPECTED:
1) sorted by date and time
2) should ont show Oct 22 entry
3) only 30th oct approved

1|	1|	Fri Oct 29 2021 00:00:00 GMT+0800 (Singapore Standard Time)|	Sat Oct 30 2021 14:00:00 GMT+0800 (Singapore Standard Time)|	false
1|	1|	Sat Oct 30 2021 00:00:00 GMT+0800 (Singapore Standard Time)|	Sat Oct 30 2021 14:00:00 GMT+0800 (Singapore Standard Time)|	false
1|	1|	Sat Oct 30 2021 00:00:00 GMT+0800 (Singapore Standard Time)|	Sat Oct 30 2021 13:00:00 GMT+0800 (Singapore Standard Time)|	true
*/
INSERT INTO Departments VALUES (1, 'firstDep');
INSERT INTO Meeting_Rooms VALUES (1,1,'firstRoom',1,5);
INSERT INTO Employees VALUES (1,'first guy', 'first@mail.com', 'Manager', 1);
INSERT INTO Contact VALUES (1, 92436283);
INSERT INTO health_declaration VALUES ('23-10-2021', 1, 36);
INSERT INTO Bookings VALUES (1, 1, '22-10-2021', '20211022 14:00:00', 1);
INSERT INTO Bookings VALUES (1, 1, '30-10-2021', '20211030 14:00:00', 1);
INSERT INTO Bookings VALUES (1, 1, '29-10-2021', '20211030 14:00:00', 1);
INSERT INTO Bookings VALUES (1, 1, '30-10-2021', '20211030 13:00:00', 1, 1);

SELECT * FROM view_booking_report('22-10-2021', 1);

-- TEST ADMIN 3 
/*
PREREQS: run with testadmin2
EXPECTED:
only show oct 30 meeting
1	1	Sat Oct 30 2021 00:00:00 GMT+0800 (Singapore Standard Time)	Sat Oct 30 2021 13:00:00 GMT+0800 (Singapore Standard Time)	2
*/
INSERT INTO Employees VALUES (2,'second guy', '2nd@mail.com', 'Junior', 1);
INSERT INTO Contact VALUES (2, 12345678);
INSERT INTO Participates VALUES (2, 1, 1, '30-10-2021', '20211030 13:00:00');
INSERT INTO Participates VALUES (2, 1, 1, '29-10-2021', '20211030 14:00:00');

SELECT * FROM view_future_meeting('22-10-2021', 1);
SELECT * FROM view_future_meeting('22-10-2021', 2);

-- TEST ADMIN 4

SELECT * FROM view_manager_report('22-10-2021', 1);
SELECT * FROM view_manager_report('22-10-2021', 2);