/* # Add department # 
Expected behavior: department is inserted without issue 
test1: insertion of 1 data -> basic 
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
If meeting room involving department deleted, should also be cascade deleted.
If 
If employee in department, an error should be thrown.


test1: insertion of 1 data -> basic 
test2: insertion of identical did with different name -> PK constraint
*/