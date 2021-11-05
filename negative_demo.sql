\! cls
\i schema.sql
\i proc.sql

\! echo __Test__1
-- Booking can only be made by a Senior or a Manager
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
-- Only manager of dept who has not resigned can approve a meeting
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
-- Only manager of dept can change capacity of a meeting
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
-- Cannot insert bookings which overlap with other bookings
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
-- Employee with fever cannot book any meetings
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
-- Employee cannot join a meeting which is full/reached maximum capacity
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

\! echo __Test__7
-- Employee with fevers cannot join any meeting
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

\! echo __Test__8
-- Employee cannot join an approved meeting
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
-- Employee cannot leave a meeting if its approved (Unless they have resigned)
BEGIN;
\! echo $$--------------------------------------------------$$
\! echo Employee cannot leave a meeting if its approved (Unless they have resigned)

CALL add_department (0, 'Accounting');

CALL add_employee('Ab', NULL, NULL, '16747133', 'Manager', 0);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Manager', 0);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 0);

CALL add_room(10, 18, 'Abata', 0, 3);

CALL book_room(10, 18,'2021-01-02', '00:00:00', '01:00:00', 1);
CALL join_meeting(10, 18,'2021-01-02', '00:00:00', '01:00:00', 2);
CALL join_meeting(10, 18,'2021-01-02', '00:00:00', '01:00:00', 3);

CALL approve_meeting(18, 10,'2021-01-02', '00:00:00', '01:00:00', 2);

CALL leave_meeting(10, 18, '2021-01-02', '00:00:00', '01:00:00', 2);

CALL remove_employee(3, '2021-01-01');

\! echo =========================
\! echo Participates Table
\! echo =========================
SELECT * FROM Participates;
\! echo $$--------------------------------------------------$$
ROLLBACK;

\! echo __Test__10
-- Resigned Employee cannot make any bookings
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
-- Resigned Employee cannot join any meetings
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







