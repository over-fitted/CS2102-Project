-- ### Populate table


-- ### Insert into Departments

CALL add_department (0, 'Accounting');
CALL add_department (1, 'Business Development');
CALL add_department (2, 'Departments');
CALL add_department (3, 'Engineering');
CALL add_department (4, 'Human Resources');     
CALL add_department (5, 'Legal');
CALL add_department (6, 'Marketing');
CALL add_department (7, 'Product Management');
CALL add_department (8, 'Research and Development');
CALL add_department (9, 'Sales');
CALL add_department (10, 'Services');
CALL add_department (11, 'Support');
CALL add_department (12, 'Training');


-- ### Insert into MeetingRooms

CALL add_room(10, 18, 'Abata', 10, 13);
CALL add_room(17, 39, 'Avamba', 8, 18);
CALL add_room(8, 6, 'Avamm', 0, 10);
CALL add_room(25, 33, 'Brightbean', 12, 14);
CALL add_room(11, 37, 'Browsetype', 1, 5);
CALL add_room(18, 5, 'Buzzster', 8, 15);
CALL add_room(37, 5, 'Cogidoo', 0, 15);
CALL add_room(40, 27, 'Demimbu', 12, 14);
CALL add_room(2, 28, 'Demizz', 2, 13);
CALL add_room(43, 17, 'Divavu', 6, 15);
CALL add_room(32, 13, 'Eabox', 10, 18);
CALL add_room(3, 16, 'Eayo', 12, 7);
CALL add_room(44, 33, 'Feedmix', 1, 8);
CALL add_room(24, 10, 'Flashdog', 11, 18);
CALL add_room(25, 29, 'Flashset', 5, 3);
CALL add_room(41, 24, 'Gevee', 4, 13);
CALL add_room(21, 25, 'JumpXS', 1, 15);
CALL add_room(16, 31, 'Lazz', 1, 12);
CALL add_room(31, 2, 'Leexo', 4, 11);
CALL add_room(25, 15, 'Meeveo', 0, 12);
CALL add_room(7, 30, 'Miboo', 10, 5);
CALL add_room(20, 33, 'Mita', 12, 14);
CALL add_room(34, 11, 'Mudo', 8, 15);
CALL add_room(18, 43, 'Ooba', 7, 5);
CALL add_room(44, 34, 'Oyonder', 12, 11);
CALL add_room(31, 25, 'Oyope', 2, 19);
CALL add_room(11, 8, 'Quimm', 3, 6);
CALL add_room(26, 11, 'Quinu', 3, 10);
CALL add_room(28, 2, 'Rhynoodle', 9, 5);
CALL add_room(2, 10, 'Skipstorm', 9, 12);
CALL add_room(25, 39, 'Skyndu', 10, 18);
CALL add_room(15, 5, 'Skyvu', 4, 14);
CALL add_room(35, 14, 'Tagcat', 5, 1);
CALL add_room(15, 7, 'Tagfeed', 6, 17);
CALL add_room(1, 29, 'Topicware', 2, 4);
CALL add_room(6, 31, 'Vidoo', 11, 14);
CALL add_room(21, 15, 'Vipe', 4, 17);
CALL add_room(33, 25, 'Voonyx', 10, 6);
CALL add_room(6, 2, 'Wikido', 3, 15);
CALL add_room(12, 43, 'Yadel', 8, 13);
CALL add_room(28, 18, 'Yata', 4, 12);
CALL add_room(41, 8, 'Youbridge', 9, 12);
CALL add_room(20, 6, 'Youopia', 2, 8);
CALL add_room(40, 24, 'Zoovu', 3, 3);

-- ### Insert into Employees

CALL add_employee('Ab', NULL, NULL, '16747133', 'Junior', 12);
CALL add_employee('Abram', NULL, NULL, '58082297', 'Junior', 2);
CALL add_employee('Aksel', NULL, NULL, '10904341', 'Manager', 4);
CALL add_employee('Arnold', NULL, NULL, '35410616', 'Manager', 0);
CALL add_employee('Bern', NULL, NULL, '42987675', 'Senior', 11);
CALL add_employee('Bertram', NULL, NULL, '69192531', 'Manager', 12);
CALL add_employee('Brit', NULL, NULL, '74110624', 'Manager', 2);
CALL add_employee('Burke', NULL, NULL, '73262691', 'Manager', 11);
CALL add_employee('Che', NULL, NULL, '28218442', 'Senior', 11);
CALL add_employee('Cherilynn', NULL, NULL, '89450099', 'Junior', 0);
CALL add_employee('Cilka', NULL, NULL, '14111512', 'Senior', 12);
CALL add_employee('Constancia', NULL, NULL, '71767899', 'Manager', 2);
CALL add_employee('Constantine', NULL, NULL, '94113180', 'Senior', 11);
CALL add_employee('Cullin', NULL, NULL, '45939764', 'Manager', 4);
CALL add_employee('Darcy', NULL, NULL, '89470328', 'Manager', 2);
CALL add_employee('Danyette', NULL, NULL, '10436515', 'Junior', 9);
CALL add_employee('Denni', NULL, NULL, '76464928', 'Manager', 5);
CALL add_employee('Donalt', NULL, NULL, '60854937', 'Senior', 11);
CALL add_employee('Ebonee', NULL, NULL, '75074045', 'Senior', 4);
CALL add_employee('Farley', NULL, NULL, '56729921', 'Junior', 1);
CALL add_employee('Flossie', NULL, NULL, '42410577', 'Junior', 6);
CALL add_employee('Francine', NULL, NULL, '39017396', 'Junior', 11);
CALL add_employee('Gaspard', NULL, NULL, '61998871', 'Junior', 3);
CALL add_employee('Glenden', NULL, NULL, '97962267', 'Senior', 4);
CALL add_employee('Gwenora', NULL, NULL, '40223135', 'Manager', 11);
CALL add_employee('Hall', NULL, NULL, '32710163', 'Manager', 6);
CALL add_employee('Hilliard', NULL, NULL, '23726721', 'Manager', 3);
CALL add_employee('Hunfredo', NULL, NULL, '70464397', 'Senior', 8);
CALL add_employee('Janith', NULL, NULL, '15658629', 'Senior', 7);
CALL add_employee('Jarvis', NULL, NULL, '76593292', 'Manager', 9);
CALL add_employee('Kearney', NULL, NULL, '27190848', 'Junior', 4);
CALL add_employee('Kirsten', NULL, NULL, '74823999', 'Senior', 7);
CALL add_employee('Kristo', NULL, NULL, '58132152', 'Junior', 10);
CALL add_employee('Laure', NULL, NULL, '23290310', 'Junior', 0);
CALL add_employee('Leonard', NULL, NULL, '71536553', 'Senior', 8);
CALL add_employee('Meridel', NULL, NULL, '69300011', 'Senior', 0);
CALL add_employee('Mick', NULL, NULL, '87297188', 'Junior', 1);
CALL add_employee('Milt', NULL, NULL, '44112334', 'Junior', 7);
CALL add_employee('Nerissa', NULL, NULL, '41717963', 'Senior', 5);
CALL add_employee('Petronille', NULL, NULL, '88848197', 'Manager', 2);
CALL add_employee('Pincas', NULL, NULL, '59369999', 'Junior', 12);
CALL add_employee('Rabbi', NULL, NULL, '26449060', 'Junior', 4);
CALL add_employee('Ravid', NULL, NULL, '55891158', 'Manager', 10);
CALL add_employee('Russell', NULL, NULL, '89476640', 'Senior', 3);
CALL add_employee('Sayre', NULL, NULL, '22002766', 'Manager', 0);
CALL add_employee('Seward', NULL, NULL, '50527006', 'Junior', 0);
CALL add_employee('Travers', NULL, NULL, '20326982', 'Senior', 9);
CALL add_employee('Wallis', NULL, NULL, '22333986', 'Junior', 12);
CALL add_employee('Wandie', NULL, NULL, '78849760', 'Senior', 11);
CALL add_employee('Wilmar', NULL, NULL, '42813905', 'Junior', 12);

-- ### Make Bookings and Join Meetings
BEGIN;

CALL book_room(10, 18,'2021-01-01', '00:00:00', '01:00:00', 5);
CALL join_meeting(10, 18,'2021-01-01', '00:00:00', '01:00:00', 4);
CALL join_meeting(10, 18,'2021-01-01', '00:00:00', '01:00:00', 33);
CALL join_meeting(10, 18,'2021-01-01', '00:00:00', '01:00:00', 6);
CALL join_meeting(10, 18,'2021-01-01', '00:00:00', '01:00:00', 23);
CALL approve_meeting(18, 10,'2021-01-01', '00:00:00', '01:00:00', 43);

CALL book_room(2, 10,'2021-01-02', '03:00:00', '04:00:00', 30);
CALL join_meeting(2, 10,'2021-01-02', '03:00:00', '04:00:00', 24);
CALL join_meeting(2, 10,'2021-01-02', '03:00:00', '04:00:00', 33);
CALL join_meeting(2, 10,'2021-01-02', '03:00:00', '04:00:00', 16);
CALL join_meeting(2, 10,'2021-01-02', '03:00:00', '04:00:00', 35);
CALL join_meeting(2, 10,'2021-01-02', '03:00:00', '04:00:00', 43);
CALL approve_meeting(10, 2,'2021-01-02', '03:00:00', '04:00:00', 30);

CALL book_room(8, 6,'2021-01-03', '03:00:00', '04:00:00', 32);
CALL join_meeting(8, 6,'2021-01-03', '03:00:00', '04:00:00', 26);
CALL join_meeting(8, 6,'2021-01-03', '03:00:00', '04:00:00', 17);
CALL join_meeting(8, 6,'2021-01-03', '03:00:00', '04:00:00', 11);
CALL join_meeting(8, 6,'2021-01-03', '03:00:00', '04:00:00', 10);
CALL join_meeting(8, 6,'2021-01-03', '03:00:00', '04:00:00', 14);
CALL approve_meeting(6, 8,'2021-01-03', '03:00:00', '04:00:00', 45);

CALL book_room(31, 25,'2021-01-04', '03:00:00', '04:00:00', 47);
CALL join_meeting(31, 25,'2021-01-04', '03:00:00', '04:00:00', 21);
CALL join_meeting(31, 25,'2021-01-04', '03:00:00', '04:00:00', 5);
CALL join_meeting(31, 25,'2021-01-04', '03:00:00', '04:00:00', 48);
CALL join_meeting(31, 25,'2021-01-04', '03:00:00', '04:00:00', 29);
CALL join_meeting(31, 25,'2021-01-04', '03:00:00', '04:00:00', 37);
CALL join_meeting(31, 25,'2021-01-04', '03:00:00', '04:00:00', 20);
CALL approve_meeting(25, 31,'2021-01-04', '03:00:00', '04:00:00', 7);

CALL book_room(41, 24,'2021-01-05', '03:00:00', '04:00:00', 49);
CALL join_meeting(41, 24,'2021-01-05', '03:00:00', '04:00:00', 46);
CALL join_meeting(41, 24,'2021-01-05', '03:00:00', '04:00:00', 14);
CALL join_meeting(41, 24,'2021-01-05', '03:00:00', '04:00:00', 30);
CALL join_meeting(41, 24,'2021-01-05', '03:00:00', '04:00:00', 23);
CALL join_meeting(41, 24,'2021-01-05', '03:00:00', '04:00:00', 41);
CALL approve_meeting(24, 41,'2021-01-05', '03:00:00', '04:00:00', 3);

CALL book_room(41, 8,'2021-01-06', '03:00:00', '04:00:00', 6);
CALL join_meeting(41, 8,'2021-01-06', '03:00:00', '04:00:00', 1);
CALL join_meeting(41, 8,'2021-01-06', '03:00:00', '04:00:00', 19);
CALL join_meeting(41, 8,'2021-01-06', '03:00:00', '04:00:00', 38);
CALL join_meeting(41, 8,'2021-01-06', '03:00:00', '04:00:00', 3);
CALL join_meeting(41, 8,'2021-01-06', '03:00:00', '04:00:00', 29);
CALL join_meeting(41, 8,'2021-01-06', '03:00:00', '04:00:00', 30);
CALL approve_meeting(8, 41,'2021-01-06', '03:00:00', '04:00:00', 30);

END;

-- ### Declare Health
CALL declare_health(1, '2021-01-02', 36.9, '02:00:00');
CALL declare_health(4, '2021-01-02', 35.9, '02:00:00');
CALL declare_health(6, '2021-01-02', 36.9, '02:00:00');
CALL declare_health(7, '2021-01-02', 34.9, '02:00:00');
CALL declare_health(13, '2021-01-02', 35.9, '02:00:00');
CALL declare_health(15, '2021-01-02', 34.9, '02:00:00');
CALL declare_health(11, '2021-01-02', 36.2, '02:00:00');
CALL declare_health(8, '2021-01-02', 37.2, '02:00:00');
CALL declare_health(45, '2021-01-02', 34.3, '02:00:00');
CALL declare_health(35, '2021-01-02', 35.4, '02:00:00');
CALL declare_health(16, '2021-01-02', 34.5, '02:00:00');
CALL declare_health(23, '2021-01-02', 35.1, '02:00:00');
CALL declare_health(21, '2021-01-02', 34.6, '02:00:00');

CALL declare_health(1, '2021-01-03', 36.9, '02:00:00');
CALL declare_health(4, '2021-01-03', 35.9, '02:00:00');
CALL declare_health(6, '2021-01-03', 36.9, '02:00:00');
CALL declare_health(7, '2021-01-03', 34.9, '02:00:00');
CALL declare_health(13, '2021-01-03', 35.9, '02:00:00');
CALL declare_health(15, '2021-01-03', 34.9, '02:00:00');
CALL declare_health(11, '2021-01-03', 36.2, '02:00:00');


CALL declare_health(1, '2021-01-04', 36.9, '02:00:00');
CALL declare_health(4, '2021-01-04', 35.9, '02:00:00');
CALL declare_health(6, '2021-01-04', 36.9, '02:00:00');
CALL declare_health(7, '2021-01-04', 34.9, '02:00:00');
CALL declare_health(13, '2021-01-04', 35.9, '02:00:00');


SELECT * FROM Departments;

SELECT * FROM MeetingRooms;

SELECT * FROM Employees;

SELECT * FROM Bookings;

SELECT * FROM Participates;

SELECT * FROM HealthDeclaration;
