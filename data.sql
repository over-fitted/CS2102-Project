-- ### Populate table

-- ### Insert into Departments

insert into Departments (did, dname) values (1, 'Human Resources');
insert into Departments (did, dname) values (2, 'Services');
insert into Departments (did, dname) values (3, 'Marketing');
insert into Departments (did, dname) values (4, 'Sales');


-- ### Insert into MeetingRooms

insert into MeetingRooms (floor, room, rname, did, capacity) values (7, 13, 'Photobean', 3, 4);
insert into MeetingRooms (floor, room, rname, did, capacity) values (6, 14, 'Podcat', 4, 1);
insert into MeetingRooms (floor, room, rname, did, capacity) values (1, 5, 'Tavu', 2, 3);
insert into MeetingRooms (floor, room, rname, did, capacity) values (7, 10, 'Skidoo', 1, 7);
insert into MeetingRooms (floor, room, rname, did, capacity) values (6, 1, 'Gabtune', 4, 7);

-- ### Insert into Employees

insert into Employees (eid, ename, email, etype, did) values (1, 'Lynnea', 'lpattison0@purevolume.com', 'Senior', 1);
insert into Employees (eid, ename, email, etype, did) values (2, 'Claude', 'ckobes1@ted.com', 'Senior', 4);
insert into Employees (eid, ename, email, etype, did) values (3, 'Daffie', 'dpatman2@infoseek.co.jp', 'Manager', 1);
insert into Employees (eid, ename, email, etype, did) values (4, 'Leland', 'lbattyll3@prlog.org', 'Manager', 4);
insert into Employees (eid, ename, email, etype, did) values (5, 'Adah', 'anudds4@cam.ac.uk', 'Manager', 2);
insert into Employees (eid, ename, email, etype, did) values (6, 'Terra', 'tbreckin5@tripadvisor.com', 'Senior', 3);
insert into Employees (eid, ename, email, etype, did) values (7, 'Page', 'pkinson6@engadget.com', 'Senior', 2);
insert into Employees (eid, ename, email, etype, did) values (8, 'Bald', 'bbains7@behance.net', 'Junior', 1);
insert into Employees (eid, ename, email, etype, did) values (9, 'Estell', 'emacgaffey8@hp.com', 'Junior', 1);
insert into Employees (eid, ename, email, etype, did) values (10, 'Tobe', 'tneagle9@indiegogo.com', 'Senior', 4);

-- ### Insert into contacts

insert into Contact (eid, phone) values (5, '6985934550');
insert into Contact (eid, phone) values (4, '5547781838');
insert into Contact (eid, phone) values (6, '3191115175');
insert into Contact (eid, phone) values (7, '2748050648');
insert into Contact (eid, phone) values (8, '4239833438');
insert into Contact (eid, phone) values (3, '5826558574');
insert into Contact (eid, phone) values (9, '2462501757');
insert into Contact (eid, phone) values (2, '6268028854');
insert into Contact (eid, phone) values (1, '2453994063');
insert into Contact (eid, phone) values (10, '7671475494');

BEGIN;
INSERT INTO Bookings VALUES (1,6,'2017-03-01'::date,'02:00:00'::time, 7);
INSERT INTO Participates VALUES (7, 1, 6, '2017-03-01'::date, '02:00:00'::time);
INSERT INTO Participates VALUES (2, 1, 6, '2017-03-01'::date, '02:00:00'::time);
INSERT INTO Bookings VALUES (5,1,'2017-03-05'::date,'02:00:00'::time, 2);
INSERT INTO Participates VALUES (2, 5, 1, '2017-03-05'::date,'02:00:00'::time);
CALL _p_approve_meeting(1, 6, '2017-03-01', '02:00:00'::time,'02:00:00'::time,5);
CALL _p_approve_meeting(5, 1, '2017-03-05', '02:00:00'::time,'02:00:00'::time,4);
CALL _p_declare_health(1, '2017-03-01', 36.4, '02:00:00'::time);
CALL _p_declare_health(1, '2017-03-01', 36.4, '03:00:00'::time);
CALL _p_declare_health(1, '2017-03-02', 35.4, '02:00:00'::time);
CALL _p_declare_health(3, '2017-03-01', 33.4, '02:00:00'::time);
CALL _p_declare_health(3, '2017-03-02', 36.2, '02:00:00'::time);
CALL _p_declare_health(3, '2017-03-03', 36.3, '02:00:00'::time);
CALL _p_declare_health(10, '2017-03-01', 36.3, '02:00:00'::time);
CALL _p_declare_health(10, '2017-03-02', 36.3, '02:00:00'::time);
CALL _p_declare_health(10, '2017-03-03', 36.2, '02:00:00'::time);
CALL _p_declare_health(10, '2017-03-03', 36.3, '03:00:00'::time);
END;