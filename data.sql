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

CALL add_employee('Jeanna', NULL, NULL, '66567280', 'Senior', 2);
CALL add_employee('Jethro', NULL, NULL, '63412013', 'Senior', 3);
CALL add_employee('Chan', NULL, NULL, '55765444', 'Junior', 2);
CALL add_employee('Giulio', NULL, NULL, '69115256', 'Senior', 1);
CALL add_employee('Jennilee', NULL, NULL, '84399505', 'Manager', 3);
CALL add_employee('Stanton', NULL, NULL, '39630089', 'Junior', 2);
CALL add_employee('Royall', NULL, NULL, '69053492', 'Manager', 2);
CALL add_employee('Vanya', NULL, NULL, '51244095', 'Senior', 1);
CALL add_employee('Justin', NULL, NULL, '87467446', 'Senior', 2);
CALL add_employee('Ethelind', NULL, NULL, '47534732', 'Junior', 1);