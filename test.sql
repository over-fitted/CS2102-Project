/* # Add department # 
Expected behavior: department is inserted without issue 
test1: insertion of 2 data with same name, diff did -> basic 
test2: insertion of identical did with different name -> PK constraint
*/

-- ## Test 1 ##
BEGIN;
    CALL add_department(1, "dept1"); 
    CALL add_department(2, "dept1");
    SELECT * FROM Departments;
COMMIT;

-- ## Test 2 ##
BEGIN;
    CALL add_department(1, "dept1"); 
    CALL add_department(1, "dept2"); 
    SELECT * FROM Departments;
COMMIT;

/* # Remove department # 
Expected behavior: 
If meeting room is in department, should also be cascade deleted.
If booking in said meeting room, should be cascaded deleted.
If employee in department, an error should be thrown.

test1: cascade deletion of meeting room that's in a department
test2: cascade deletion of booking in a meeting room that's in department
test3: deletion of department where an employee exists
*/

-- ## Test 1 ##
BEGIN;
    -- initialize data
    INSERT INTO Departments VALUES(1, "dept1");
    INSERT INTO Departments VALUES(2, "dept2");
    INSERT INTO MeetingRooms VALUES(1, 1, "room", 1, )
    SELECT * FROM Departments;
    SELECT * From MeetingRooms;
    remove_department(1);
    SELECT * FROM Departments;
    SELECT * From MeetingRooms;
COMMIT;

-- ## Test 2 ##
BEGIN;
    CALL add_department(1, "dept1"); 
    CALL add_department(1, "dept2"); 
    SELECT * FROM Departments;
COMMIT;