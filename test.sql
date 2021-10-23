/* # Add department # 
Expected behavior: department is inserted without issue 
test1: insertion of 2 data with same name, diff did -> basic 
test2: insertion of identical did with different name -> PK constraint
*/

-- ## Test 1 ##
-- BEGIN;
--     CALL add_department(1, 'dept1'); 
--     CALL add_department(2, 'dept1');
--     SELECT * FROM Departments;
-- COMMIT;

-- -- ## Test 2 ##
-- BEGIN;
--     CALL add_department(1, 'dept1'); 
--     CALL add_department(1, 'dept2'); 
--     SELECT * FROM Departments;
-- COMMIT;

/* # Remove department # 
Expected behavior: 
If meeting room is in department, should also be cascade deleted.
If booking in said meeting room, should be cascaded deleted.
If employee in department, an error should be thrown.

test1: cascade deletion of meeting room that's in a department
test2: cascade deletion of booking in a meeting room that's in department
*/

-- ## Test 1 ##
-- BEGIN;
--     -- initialize data
--     INSERT INTO Departments VALUES(1, 'dept1');
--     INSERT INTO Departments VALUES(2, 'dept2');
--     INSERT INTO MeetingRooms VALUES(1, 1, 'room1', 1, '2017-04-04', 10);
--     SELECT * FROM Departments;
--     SELECT * From MeetingRooms;

--     -- test
--     CALL remove_department(1);
--     SELECT * FROM Departments;
--     SELECT * From MeetingRooms;
-- COMMIT;

-- -- ## Test 2 ##
-- BEGIN;

--     -- initialize data
--     INSERT INTO Departments VALUES(1, 'dept1');
--     INSERT INTO Departments VALUES(2, 'dept2');
--     INSERT INTO MeetingRooms VALUES(1, 1, 'room1', 1, '2017-04-04', 10);
--     INSERT INTO Employees VALUES(1, 'employee1', '1@office.org', 'Manager', 2, '2017-04-04', '96862278', NULL, NULL);
--     INSERT INTO Bookings VALUES(1, 1, '2017-04-04', '02:00:00', 1, NULL);

--     SELECT * FROM Departments;
--     SELECT * FROM MeetingRooms;
--     SELECT * FROM Employees;
--     SELECT * FROM Bookings;

--     CALL remove_department(1);

--     SELECT * FROM Departments;
--     SELECT * FROM MeetingRooms;
--     SELECT * FROM Employees;
--     SELECT * FROM Bookings;
-- COMMIT;

/* # Add room # 
Expected behavior: add a new room into the MeetingRooms Table.
Test: trivial test to allow insertion.
*/

-- ## Test 1 ##
-- BEGIN;

--     -- initialize data
--     INSERT INTO Departments VALUES(1, 'dept1');
--     INSERT INTO MeetingRooms VALUES(1, 1, 'room1', 1, '2017-04-04', 10);
--     SELECT * FROM MeetingRooms;

--     -- test
--     CALL add_room(1, 2, 'room2', 1, 10);
--     SELECT * FROM MeetingRooms;

-- COMMIT;



/* # Change capacity # 
Expected behavior: 
Will change the capacity of a given meeting room. 
Should trigger a deletion of all future bookings in violation.
Test1: can change capacity, but trigger will not change anything
Test2: trigger should delete violating future bookings.
*/

-- ## Test 1 ##
-- BEGIN;

--     -- initialize data
--     INSERT INTO Departments VALUES(1, 'dept1');
--     INSERT INTO MeetingRooms VALUES(1, 1, 'room1', 1, '2017-04-04', 10);
--     INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '96862278', NULL, NULL);
--     INSERT INTO Employees VALUES(2, 'employee2', '2@office.org', 'Junior', 1, NULL, 'other', NULL, NULL);
--     INSERT INTO Bookings VALUES(1, 1, '2017-04-05', '02:00:00', 1, NULL);

--     SELECT * FROM Departments;
--     SELECT * FROM MeetingRooms;
--     SELECT * FROM Employees;
--     SELECT * FROM Bookings;

--     -- test
--     CALL change_capacity(1, 1, 5, '2017-04-04', 1);

--     SELECT * FROM Departments;
--     SELECT * FROM MeetingRooms;
--     SELECT * FROM Employees;
--     SELECT * FROM Bookings;
-- COMMIT;

-- ## Test 2 ##
BEGIN;

    -- initialize data
    INSERT INTO Departments VALUES(1, 'dept1');
    INSERT INTO Departments VALUES(2, 'dept2');
    INSERT INTO MeetingRooms VALUES(1, 1, 'room1', 1, '2017-04-04', 10);
    INSERT INTO MeetingRooms VALUES(2, 1, 'room2', 1, '2017-04-04', 10);
    INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '96862278', NULL, NULL);
    INSERT INTO Employees VALUES(2, 'employee2', '2@office.org', 'Junior', 1, NULL, 'other', NULL, NULL);
    INSERT INTO Bookings VALUES(1, 1, '2017-04-05', '02:00:00', 1, NULL);
    INSERT INTO Bookings VALUES(1, 2, '2017-04-05', '02:00:00', 2, NULL);
    INSERT INTO Participates VALUES(1, 1, 2, '2017-04-05', '02:00:00');

    SELECT * FROM MeetingRooms;
    SELECT * FROM Bookings;
    SELECT * FROM Participates;


    -- test
    CALL change_capacity(1, 1, 5, '2017-04-04', 1);
    CALL change_capacity(2, 1, 1, '2017-04-04', 1);

    SELECT * FROM MeetingRooms;
    SELECT * FROM Bookings;
    SELECT * FROM Participates;
COMMIT;

/* # Add employee # 
Expected behavior: 
Will change the capacity of a given meeting room. 
Should trigger a deletion of all future bookings in violation.
Test1: can change capacity, but trigger will not change anything
Test2: trigger should delete violating future bookings.
*/