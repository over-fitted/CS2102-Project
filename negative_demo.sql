\! cls
\i schema.sql
\i proc.sql

\! echo __Test__1
-- Booking can only be made by a Senior or a Manager, relies on _tf_bookingByBooker
BEGIN;
\! echo $$--------------------------------------------------$$
\! echo Booking can only be made by a Senior or a Manager

CALL add_department (0, 'Accounting');

CALL add_employee('Ab', NULL, NULL, '16747133', 'Junior', 0);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Senior', 0);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 0);

CALL add_room(10, 18, 'Abata', 0, 2);

CALL book_room(10, 18,'2021-01-01', '00:00:00', '01:00:00', 1);
CALL book_room(10, 18,'2021-01-02', '00:00:00', '01:00:00', 2);
CALL book_room(10, 18,'2021-01-03', '00:00:00', '01:00:00', 3);

\! echo =========================
\! echo Bookings Table
\! echo =========================

SELECT * FROM Bookings;
\! echo $$--------------------------------------------------$$
ROLLBACK;

\! echo __Test__2
-- Only manager of dept who has not resigned can approve a meeting, relies on an internal check in approve_meeting 
-- procedure to ensure manager's dept is the same as the room's dept.
BEGIN;
\! echo $$--------------------------------------------------$$
\! echo Only manager of dept who has not resigned can approve a meeting

CALL add_department (0, 'Accounting');

CALL add_employee('Ab', NULL, NULL, '16747133', 'Manager', 0);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Manager', 0);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 0);

CALL add_room(10, 18, 'Abata', 0, 3);

CALL book_room(10, 18,'2021-01-02', '00:00:00', '01:00:00', 1);

CALL join_meeting(10, 18,'2021-01-02', '00:00:00', '01:00:00', 2);
CALL join_meeting(10, 18,'2021-01-02', '00:00:00', '01:00:00', 3);

CALL book_room(10, 18,'2021-01-02', '03:00:00', '04:00:00', 1);

CALL approve_meeting(18, 10,'2021-01-02', '00:00:00', '01:00:00', 2);

\! echo =========================
\! echo Bookings Table
\! echo =========================
SELECT * FROM Bookings;

CALL remove_employee(3, '2021-01-01');
CALL approve_meeting(18, 10,'2021-01-02', '00:00:00', '01:00:00', 3);

\! echo $$--------------------------------------------------$$
ROLLBACK;

\! echo __Test__3
-- Only manager of dept can change capacity of a meeting, 
-- relies on an internal check in change_capacity.
BEGIN;
\! echo $$--------------------------------------------------$$
\! echo Only manager of dept can change capacity of a meeting

CALL add_department (0, 'Accounting');
CALL add_department (1, 'Engineering');

CALL add_employee('Ab', NULL, NULL, '16747133', 'Manager', 0);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Manager', 1);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 0);

CALL add_room(10, 18, 'Abata', 0, 3);

CALL change_capacity(10, 18, 2, '2021-01-01', 2);

CALL change_capacity(10, 18, 2, '2021-01-01', 3);

\! echo =========================
\! echo MeetingRooms Table
\! echo =========================
SELECT * FROM MeetingRooms;
\! echo $$--------------------------------------------------$$
ROLLBACK;

\! echo __Test__4
-- Cannot insert bookings which overlap with other bookings, relies on the Primary Key constraint on Bookings, which prevents
-- any two overlapping booking by ensuring that the (room, floor, date, time) are unique.
BEGIN;
\! echo $$--------------------------------------------------$$
\! echo Cannot insert bookings which overlap with other bookings

CALL add_department (0, 'Accounting');

CALL add_employee('Ab', NULL, NULL, '16747133', 'Manager', 0);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Manager', 0);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 0);

CALL add_room(10, 18, 'Abata', 0, 3);

CALL book_room(10, 18,'2021-01-02', '00:00:00', '01:00:00', 1);
CALL book_room(10, 18,'2021-01-02', '00:00:00', '01:00:00', 2);
\! echo $$--------------------------------------------------$$
ROLLBACK;

\! echo __Test__5
-- Employee with fever cannot book any meetings, handled by trigger _tf_feverCannotBook, which blocks the booking if the employee's
-- latest temperature declaration is above 37.5 degrees.
BEGIN;
\! echo $$--------------------------------------------------$$
\! echo Employee with fever cannot book any meetings

CALL add_department (0, 'Accounting');

CALL add_employee('Ab', NULL, NULL, '16747133', 'Manager', 0);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Manager', 0);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 0);

CALL add_room(10, 18, 'Abata', 0, 2);

CALL book_room(10, 18,'2021-01-01', '00:00:00', '01:00:00', 1);

CALL declare_health(1, '2021-01-01', 37.8,'02:00:00');

CALL book_room(10, 18,'2021-01-01', '03:00:00', '04:00:00', 1);

\! echo =========================
\! echo Bookings Table
\! echo =========================

SELECT * FROM Bookings;
\! echo $$--------------------------------------------------$$
ROLLBACK;

\! echo __Test__6
-- Employee with fevers cannot join any meeting, handled by trigger _tf_feverCannotJoin, which blocks the joining if the employee's
-- latest temperature declaration is above 37.5 degrees.
BEGIN;
\! echo $$--------------------------------------------------$$
\! echo Employee with fevers cannot join any meeting

CALL add_department (0, 'Accounting');

CALL add_employee('Ab', NULL, NULL, '16747133', 'Manager', 0);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Manager', 0);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 0);

CALL add_room(10, 18, 'Abata', 0, 2);

CALL book_room(10, 18,'2021-01-01', '00:00:00', '01:00:00', 1);

CALL declare_health(2, '2021-01-01', 37.8,'02:00:00');

CALL join_meeting(10, 18,'2021-01-01', '00:00:00', '01:00:00', 2);

\! echo =========================
\! echo Participates Table
\! echo =========================

SELECT * FROM Participates;
\! echo $$--------------------------------------------------$$

ROLLBACK;

\! echo __Test__7
-- Employee cannot join a meeting which is full/reached maximum capacity, handled by _tf_bookingWithinCapacity, which blocks the joining if 
-- the meeting is full/reached maximum capacity.
BEGIN;
\! echo $$--------------------------------------------------$$
\! echo Employee cannot join a meeting which is full/reached maximum capacity
CALL add_department (0, 'Accounting');

CALL add_employee('Ab', NULL, NULL, '16747133', 'Manager', 0);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Manager', 0);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 0);

CALL add_room(10, 18, 'Abata', 0, 2);

CALL book_room(10, 18,'2021-01-01', '00:00:00', '01:00:00', 1);
CALL join_meeting(10, 18,'2021-01-01', '00:00:00', '01:00:00', 2);

--Should not occur Max capacity reached
CALL join_meeting(10, 18,'2021-01-01', '00:00:00', '01:00:00', 3);

\! echo =========================
\! echo Participates Table
\! echo =========================

SELECT * FROM Participates;
\! echo $$--------------------------------------------------$$
ROLLBACK;



\! echo __Test__8
-- Employee cannot join an approved meeting, handled by _tf_approvalCheckToJoin, 
-- which blocks the joining if the meeting is approved.
BEGIN;
\! echo $$--------------------------------------------------$$
\! echo Employee cannot join an approved meeting

CALL add_department (0, 'Accounting');

CALL add_employee('Ab', NULL, NULL, '16747133', 'Manager', 0);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Manager', 0);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 0);

CALL add_room(10, 18, 'Abata', 0, 2);

CALL book_room(10, 18,'2021-01-02', '00:00:00', '01:00:00', 1);

CALL approve_meeting(18, 10,'2021-01-02', '00:00:00', '01:00:00', 2);

CALL join_meeting(10, 18,'2021-01-02', '00:00:00', '01:00:00', 3);

\! echo =========================
\! echo Participates Table
\! echo =========================
SELECT * FROM Participates;

\! echo $$--------------------------------------------------$$
ROLLBACK;

\! echo __Test__9
-- Employee cannot leave a meeting if its approved (Unless they have resigned), handled by _tf_approvalCheckToLeave, 
-- which blocks the leaving if the meeting is approved, unless the employee has resigned or is a close contact.
BEGIN;
\! echo $$--------------------------------------------------$$
\! echo Employee cannot leave a meeting if its approved (Unless they have resigned)

CALL add_department (0, 'Accounting');

CALL add_employee('Ab', NULL, NULL, '16747133', 'Manager', 0);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Manager', 0);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 0);
CALL add_employee('Apron', NULL, NULL, '20924311', 'Manager', 0);

CALL add_room(10, 18, 'Abata', 0, 4);

CALL book_room(10, 18,'2021-01-02', '00:00:00', '01:00:00', 1);
CALL join_meeting(10, 18,'2021-01-02', '00:00:00', '01:00:00', 2);
CALL join_meeting(10, 18,'2021-01-02', '00:00:00', '01:00:00', 3);
CALL join_meeting(10, 18,'2021-01-02', '00:00:00', '01:00:00', 4);

CALL approve_meeting(18, 10,'2021-01-02', '00:00:00', '01:00:00', 2);

CALL leave_meeting(10, 18, '2021-01-02', '00:00:00', '01:00:00', 2);

CALL remove_employee(3, '2021-01-01');

CALL declare_health(4, '2021-01-01', 37.8,'01:00:00');

\! echo =========================
\! echo Participates Table
\! echo =========================
SELECT * FROM Participates;
\! echo $$--------------------------------------------------$$
ROLLBACK;

\! echo __Test__10
-- Resigned Employee cannot make any bookings, handled by _tf_resignedCannotBook, 
-- which blocks the booking if the employee has resigned.
BEGIN;
\! echo $$--------------------------------------------------$$
\! echo Resigned Employee cannot make any bookings

CALL add_department (0, 'Accounting');

CALL add_employee('Ab', NULL, NULL, '16747133', 'Manager', 0);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Manager', 0);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 0);

CALL add_room(10, 18, 'Abata', 0, 2);

CALL remove_employee(1, '2021-01-01');

CALL book_room(10, 18,'2021-01-01', '00:00:00', '01:00:00', 1);

\! echo =========================
\! echo Bookings Table
\! echo =========================
SELECT * FROM Bookings;

\! echo $$--------------------------------------------------$$
ROLLBACK;

\! echo __Test__11
-- Resigned Employee cannot join any meetings, handled by _tf_resignedCannotJoin,
-- which blocks the joining if the employee has resigned.
BEGIN;
\! echo $$--------------------------------------------------$$
\! echo Resigned Employee cannot join any meetings

CALL add_department (0, 'Accounting');

CALL add_employee('Ab', NULL, NULL, '16747133', 'Manager', 0);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Manager', 0);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 0);

CALL add_room(10, 18, 'Abata', 0, 2);

CALL book_room(10, 18,'2021-01-02', '00:00:00', '01:00:00', 1);

CALL remove_employee(2, '2021-01-01');

CALL join_meeting(10, 18,'2021-01-02', '00:00:00', '01:00:00', 2);

\! echo =========================
\! echo Participates Table
\! echo =========================
SELECT * FROM Participates;

\! echo $$--------------------------------------------------$$
ROLLBACK;







