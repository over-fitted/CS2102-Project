DROP TABLE IF EXISTS Departments, MeetingRooms, Employees, Contact, HealthDeclaration, Bookings, Participates CASCADE;

CREATE TABLE Departments (
    did INTEGER PRIMARY KEY,
    dname TEXT NOT NULL
);

--TRIGGER: change meetings that violate upon capacity change from the day after
--Intentionally ignore past capacities and change dates
CREATE TABLE MeetingRooms (
    floor INTEGER CHECK (floor > 0),
    room INTEGER CHECK (room > 0),
    rname VARCHAR(50) NOT NULL,
    did INTEGER NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    FOREIGN KEY (did) REFERENCES Departments(did),
    PRIMARY KEY (floor, room)
);

CREATE TABLE Employees (
    eid INTEGER PRIMARY KEY,
    ename VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL CONSTRAINT _c_valid_email CHECK (email LIKE '%@%.%'),
    etype VARCHAR(7) NOT NULL CONSTRAINT _c_valid_etype CHECK (etype IN ('Manager', 'Senior', 'Junior')),
    did INTEGER NOT NULL,
    resigned_date DATE,
    -- Bookable derived attribute checking ISA Manger, Senior
    FOREIGN KEY (did) REFERENCES Departments(did)
);

--TODO: Check format of contact number
--TRIGGER: employees must have contact
CREATE TABLE Contact (
    eid INTEGER PRIMARY KEY,
    phone VARCHAR(50),
    FOREIGN KEY (eid) REFERENCES Employees(eid) -- intentional no cascade to check for bad eid modification
);

--TRIGGER: Fever event
CREATE TABLE HealthDeclaration (
    date DATE,
    eid INTEGER NOT NULL,
    temperature INTEGER NOT NULL CHECK (temperature > 30),
    FOREIGN KEY (eid) REFERENCES Employees(eid),  -- intentional no cascade to check for bad eid modification
    PRIMARY KEY (date, eid)
);

--TRIGGER: must have at least one participant, let it be booker
CREATE TABLE Bookings (
    room INTEGER,
    floor INTEGER,
    date DATE,
    time TIMESTAMP,
    booker_id INTEGER NOT NULL, 
    approver_id INTEGER,
    FOREIGN KEY (booker_id) REFERENCES Employees (eid),
    FOREIGN KEY (approver_id) REFERENCES Employees (eid),
    FOREIGN KEY (room, floor) REFERENCES MeetingRooms(room, floor),
    PRIMARY KEY (room, floor, date, time)
);

--TRIGGER: Check capacity
--TRIGGER: When create a booking, insert booker into
CREATE TABLE Participates (
    eid INTEGER,
    room INTEGER,
    floor INTEGER,
    date DATE,
    time TIMESTAMP,
    PRIMARY KEY (eid, room, floor, date, time),
    FOREIGN KEY (room, floor, date, time) REFERENCES Bookings (room, floor, date, time)
);