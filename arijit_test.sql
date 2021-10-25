
-- All test cases for CORE 2 to CORE 5

/* ~~~~~~ book_room --> CORE 2 # 
Expected behavior: room is booked with no issue 
*/

-- ## Test 1 ##
/*
-> Bookings by a senior and a manager
-> Same time, day and diff location
-> One hour slot
*/

\i 'schema.sql'
\i 'proc.sql'
BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test 
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	CALL book_room(2, 2, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	SELECT * FROM Bookings;

ROLLBACK;


-- ## Test 2 ##
/*
-> Bookings by a senior and a manager
-> Same time, day and diff location
-> Multiple hour slot
*/
BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test 
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '18:00:00'::TIME, 1);
	CALL book_room(2, 2, '2017-04-05'::DATE, '12:00:00'::TIME, '17:00:00'::TIME, 2);
	SELECT * FROM Bookings;

ROLLBACK;

-- ## Test 3 ##
/*
-> Bookings by a senior and a manager
-> Same time, day and same location [CLASHING**]
-> Multiple hour slot
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test 
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '17:00:00'::TIME, 1);
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '17:00:00'::TIME, 2);
	SELECT * FROM Bookings;

ROLLBACK;

-- ## Test 4 ##
/*
-> Bookings by a Junior
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test 
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 3);
	SELECT * FROM Bookings;

ROLLBACK;


-- ## Test 5 ##
/*
-> Bookings by a senior
-> Not booked on the hour
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);

	-- test 
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:32:00'::TIME, '13:00:00'::TIME, 2);
	SELECT * FROM Bookings;

ROLLBACK;

-- ## Test 6 ##
/*
-> Bookings by a senior
-> The senior has fever
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO HealthDeclaration VALUES('2017-04-05', '11:00:00'::TIME, 2, 38.4);

	-- test
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	SELECT * FROM Bookings;

ROLLBACK;

-- ## Test 7 ##
/*
-> Bookings by a senior
-> floor and room does not exist
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);

	-- test
	CALL book_room(34, 65, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	SELECT * FROM Bookings;

ROLLBACK;

-- ## Test 8 ##
/*
-> Bookings by a senior
-> BOT THE SENIOR HAS RESIGNED***************
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, '2017-04-04', NULL, '96862278', NULL);

	-- test
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	SELECT * FROM Bookings;

ROLLBACK;


/* ~~~~~~ unbook_room --> CORE 3 # 
Expected behavior: room is unbooked with no issue 
*/

-- ## Test 1 ##
/*
-> Bookings by a senior and a manager
-> One hour slot
-> Manager unbooks his booking
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room has be tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	CALL book_room(2, 2, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	SELECT * FROM Bookings;

	CALL unbook_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	SELECT * FROM Bookings;

ROLLBACK;


-- ## Test 2 ##
/*
-> Bookings by a senior and a manager
-> One hour slot
-> Manager unbooks his booking
--> unbooked meeting DOES NOT EXIST (wrong year)
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);

	-- test (book_room has be tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	SELECT * FROM Bookings;

	CALL unbook_room(1, 1, '2019-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	SELECT * FROM Bookings;

ROLLBACK;

-- ## Test 3 ##
/*
-> Bookings by a manager
-> Manager unbooks his booking
--> unbooked meeting DOES NOT EXIST (Start time is too early)
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);

	-- test (book_room has be tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '15:00:00'::TIME, 1);
	SELECT * FROM Bookings;
	-- The unbooking should still happen
	CALL unbook_room(1, 1, '2017-04-05'::DATE, '11:00:00'::TIME, '15:00:00'::TIME, 1);
	SELECT * FROM Bookings;

ROLLBACK;

-- ## Test 4 ##
/*
-> Bookings by a manager
-> Manager unbooks his booking
--> unbooks middle portion of a long meeting
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);

	-- test (book_room has be tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '18:00:00'::TIME, 1);
	SELECT * FROM Bookings;
	-- The unbooking should still happen
	CALL unbook_room(1, 1, '2017-04-05'::DATE, '14:00:00'::TIME, '16:00:00'::TIME, 1);
	SELECT * FROM Bookings;

ROLLBACK;

-- ## Test 5 ##
/*
-> Bookings by a manager that is APPROVED********
-> One hour slot
-> Manager unbooks his booking
--> unbooks middle portion of a long meeting
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	-- MANUALLY insert booking and approval (manager approves himself)
	INSERT INTO Bookings VALUES(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, 1, 1);
	INSERT INTO Bookings VALUES(1, 1, '2017-04-05'::DATE, '13:00:00'::TIME, 1, 1);

	SELECT * FROM Bookings;

	-- The unbooking should still happen
	CALL unbook_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '14:00:00'::TIME, 1);
	SELECT * FROM Bookings;

ROLLBACK;

-- ## Test 6 ##
/*
-> Bookings by a manager 
-> One hour slot
-> Senior tries unbooks the Manager's booking (no sabotage rule)
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room has be tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	SELECT * FROM Bookings;

	CALL unbook_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	SELECT * FROM Bookings;

ROLLBACK;

-- ## Test 7 ##
/*
-> Bookings by a manager 
-> Senior and Junior joins the meeting
-> Manager unbooks meeting (show that it CASCADES to Participates)
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room has be tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	-- manually insert participants (Senior and Junior)
	INSERT INTO Participates VALUES(2, 1, 1, '2017-04-05'::DATE, '12:00:00'::TIME);
	INSERT INTO Participates VALUES(3, 1, 1, '2017-04-05'::DATE, '12:00:00'::TIME);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

	CALL unbook_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;
ROLLBACK;


/* ~~~~~~ join_meeting --> CORE 4 # 
Expected behavior: participant joins booking with no issue 
*/

-- ## Test 1 ##
/*
-> Bookings by a manager 
-> Senior and Junior joins the meeting
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room has be tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

ROLLBACK;

-- ## Test 2 ##
/*
-> Bookings by a manager 
-> Senior and Junior joins the meeting
But Junior joins at the wrong time
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room has be tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '14:00:00'::TIME, '15:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

ROLLBACK;


-- ## Test 3 ##
/*
-> Bookings by a manager 
-> Senior and Junior joins the meeting
But Junior has a fever
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');
	INSERT INTO HealthDeclaration VALUES('2017-04-05', '11:00:00'::TIME, 1, 37.1);
	INSERT INTO HealthDeclaration VALUES('2017-04-05', '11:00:00'::TIME, 2, 37.5);
	INSERT INTO HealthDeclaration VALUES('2017-04-05', '11:00:00'::TIME, 3, 38.4);

	-- test (book_room has be tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

ROLLBACK;

-- ## Test 4 ##
/*
-> Bookings by a manager 
-> Senior joins the meeting and Manager approves it
But Junior still tries to join it
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room has be tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	
	-- manually approve booking
	UPDATE Bookings SET approver_id = 1; 

	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

ROLLBACK;

-- ## Test 5 ##
/*
-> Bookings by a manager 
-> Senior joins the meeting and Manager approves it
Junior is resigned but tries to join
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room has be tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	
	-- manually approve booking
	UPDATE Employees SET resigned_date = '2017-04-04' WHERE eid = 3; 

	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

ROLLBACK;

-- ## Test 6 ##
/*
-> Bookings by a manager 
-> Senior and Junior joins the meeting
-> multi hour booking
-> Senior and Junior attend at different start and end times
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room has be tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '18:00:00'::TIME, 1);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '13:00:00'::TIME, '16:00:00'::TIME, 2);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '15:00:00'::TIME, '17:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

ROLLBACK;


/* ~~~~~~ leave_meeting --> CORE 5 # 
Expected behavior: participant joins booking with no issue 
*/

-- ## Test 1 ##
/*
-> Bookings by a manager 
-> Senior and Junior joins the meeting
-> Senior leaves the meeting
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room and join_meeting have been tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

	CALL leave_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

ROLLBACK;


-- ## Test 2 ##
/*
-> Bookings by a manager 
-> Senior and Junior joins the meeting
-> Senior leaves the WRONG**** meeting (wrong year)
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room and join_meeting have been tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

	CALL leave_meeting(1, 1, '2018-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

ROLLBACK;

-- ## Test 3 ##
/*
-> Bookings by a manager 
-> Senior and Junior joins the meeting
-> Manager approves the meeting
-> But Senior tried to leave the meeting
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room and join_meeting have been tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 1);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 2);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 3);
	UPDATE Bookings SET approver_id = 1; 
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

	CALL leave_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '13:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

ROLLBACK;


-- ## Test 4 ##
/*
-> Bookings by a manager 
-> Senior and Junior joins the meeting
-> multi hour meeting
-> Junior and Senior leave at different times
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room and join_meeting have been tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '16:00:00'::TIME, 1);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '16:00:00'::TIME, 2);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '16:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

	CALL leave_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '14:00:00'::TIME, 2);
	CALL leave_meeting(1, 1, '2017-04-05'::DATE, '13:00:00'::TIME, '15:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

ROLLBACK;

-- ## Test 5 ##
/*
-> Bookings by a manager (Multi hour)
-> Senior and Junior joins the meeting
-> Manager leaves the meeting
*/

BEGIN;
	-- initialise data
	INSERT INTO Departments VALUES(1, 'accounting');
	INSERT INTO Departments VALUES(2, 'finance');
	INSERT INTO MeetingRooms VALUES(1, 1, 'money_counting_room', 1, '2017-04-04', 12);
	INSERT INTO MeetingRooms VALUES(2, 2, 'stock_exchange_room', 2, '2017-04-04', 8);
	INSERT INTO Employees VALUES(1, 'manager1', '1@office.org', 'Manager', 1, NULL, '63107790', NULL, NULL);
	INSERT INTO Employees VALUES(2, 'senior2', '2@office.org', 'Senior', 1, NULL, NULL, '96862278', NULL);
	INSERT INTO Employees VALUES(3, 'employee3', '3@office.org', 'Junior', 1, NULL, NULL, NULL, '97700237');

	-- test (book_room and join_meeting have been tested so I am using it here)
	CALL book_room(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '17:00:00'::TIME, 1);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '17:00:00'::TIME, 2);
	CALL join_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '17:00:00'::TIME, 3);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

	CALL leave_meeting(1, 1, '2017-04-05'::DATE, '12:00:00'::TIME, '17:00:00'::TIME, 1);
	SELECT * FROM Bookings;
	SELECT * FROM Participates;

ROLLBACK;