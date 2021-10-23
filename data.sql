-- ### Populate table
-- ### Insert into Departments

CALL add_department (0, 'Human Resources');
CALL add_department (1, 'Services');
CALL add_department (2, 'Marketing');
CALL add_department (3, 'Sales');


-- ### Insert into MeetingRooms

CALL add_room(4, 6, 'Eimbee', 0, 13);
CALL add_room(5, 8, 'Blogspan', 0, 14);
CALL add_room(2, 4, 'Photospace', 3, 1);
CALL add_room(8, 3, 'Brainverse', 3, 9);
CALL add_room(3, 8, 'Quire', 1, 16);
CALL add_room(4, 9, 'Topicblab', 3, 6);
CALL add_room(5, 3, 'Photospace', 2, 14);
CALL add_room(9, 5, 'Topiczoom', 2, 14);
CALL add_room(2, 5, 'Demivee', 2, 10);
CALL add_room(7, 2, 'Yozio', 3, 2);

-- ### Insert into Employees

CALL add_employee('Jeanna', NULL, NULL, '10688552', 'Senior', 1);
CALL add_employee('Jethro', NULL, NULL, '84629073', 'Manager', 0);
CALL add_employee('Chan', NULL, NULL, '80898916', 'Senior', 1);
CALL add_employee('Giulio', NULL, NULL, '26298711', 'Manager', 1);
CALL add_employee('Jennilee', NULL, NULL, '23822220', 'Senior', 1);
CALL add_employee('Stanton', NULL, NULL, '27038304', 'Manager', 0);
CALL add_employee('Royall', NULL, NULL, '66345371', 'Senior', 2);
CALL add_employee('Vanya', NULL, NULL, '41244793', 'Senior', 0);
CALL add_employee('Justin', NULL, NULL, '44636701', 'Manager', 2);
CALL add_employee('Ethelind', NULL, NULL, '44929266', 'Senior', 2);