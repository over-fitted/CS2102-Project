\i schema.sql
\i proc.sql

-- 5) show manager report for each manager starting from LATE date
-- 6) each manager approves 1 booking
-- 7) junior joins senior's booking
-- 8) everyone joins 1 booking to show capacity
-- 8) manager 2 has a fever
-- 9) manager 1 leaves    
    
-- SETUP
-- 1) Add 2 departments
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
CALL book_room(1, 1, '2021-2-2'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 6);

SELECT * FROM Bookings;

-- 5) Check manager report for both managers. This shows that book_room and manager report behaviour are consistent with expectations
SELECT * FROM view_manager_report('2021-1-1', 1);
SELECT * FROM view_manager_report('2021-2-1', 1);
SELECT * FROM view_manager_report('2021-1-1', 5);

-- 6) 
CALL join_meeting(1, 1, '2021-2-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
CALL join_meeting(1, 1, '2021-2-1'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 2);
CALL join_meeting(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 2);
CALL join_meeting(1, 1, '2021-2-2'::DATE, '11:00:00'::TIME, '12:00:00'::TIME, 2);

CALL approve_meeting(1, 1, '2021-1-1'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);
CALL approve_meeting(1, 1, '2021-2-2'::DATE, '10:00:00'::TIME, '11:00:00'::TIME, 1);

-- PRE-BOOKING CALLS
SELECT * FROM search_room(10, '2021-1-1', '10:00:00', '13:00:00');