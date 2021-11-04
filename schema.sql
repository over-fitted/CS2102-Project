DROP TABLE IF EXISTS Departments, MeetingRooms, Employees, HealthDeclaration, Bookings, Participates, Temp_Contact_Tracing CASCADE;

CREATE TABLE Departments (
    did INTEGER PRIMARY KEY,
    dname VARCHAR(50) NOT NULL
);

--TRIGGER: change meetings that violate upon capacity change from the day after
--Intentionally ignore past capacities and change dates
CREATE TABLE MeetingRooms (
    floor INTEGER CHECK (floor > 0),
    room INTEGER CHECK (room > 0),
    rname VARCHAR(50) NOT NULL,
    did INTEGER NOT NULL,
    capacity_change_date DATE NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    FOREIGN KEY (did) REFERENCES Departments(did) ON DELETE CASCADE,
    PRIMARY KEY (floor, room)
);

CREATE TABLE Employees (
    eid INTEGER PRIMARY KEY,
    ename VARCHAR(50) NOT NULL,
    email VARCHAR(50) NOT NULL CONSTRAINT _c_valid_email CHECK (email LIKE '%@%.%'),
    etype VARCHAR(7) NOT NULL CONSTRAINT _c_valid_etype CHECK (etype IN ('Manager', 'Senior', 'Junior')),
    did INTEGER NOT NULL,
    resigned_date DATE,
    home_number VARCHAR(50) CHECK(home_number ~ '^[+-0-9]+$'), -- can stay in same house
    mobile_number VARCHAR(50) UNIQUE CHECK(home_number ~ '^[+-0-9]+$'), -- need to contact
    office_number VARCHAR(50) CHECK(home_number ~ '^[+-0-9]+$'), -- can share office number 
    
    CONSTRAINT _c_mustHaveContact CHECK ((home_number IS NOT NULL) OR (mobile_number IS NOT NULL) OR (office_number IS NOT NULL)),
    FOREIGN KEY (did) REFERENCES Departments(did)
);

--TRIGGER: Fever event
CREATE TABLE HealthDeclaration (
    date DATE,
    time TIME,
    eid INTEGER NOT NULL,
    temperature NUMERIC NOT NULL CONSTRAINT _c_validTemperature CHECK (temperature >= 34 AND temperature <= 43),
    FOREIGN KEY (eid) REFERENCES Employees(eid),  -- intentional no cascade to check for bad eid modification
    PRIMARY KEY (date, time, eid)
);

--TRIGGER: must have at least one participant, let it be booker
CREATE TABLE Bookings (
    room INTEGER,
    floor INTEGER,
    date DATE,
    time TIME CONSTRAINT _c_onTheHour CHECK (EXTRACT(MINUTE FROM time) = 0 AND EXTRACT(SECOND FROM time) = 0 AND EXTRACT(milliseconds FROM time) = 0),
    booker_id INTEGER NOT NULL, 
    approver_id INTEGER,
    FOREIGN KEY (booker_id) REFERENCES Employees (eid),
    FOREIGN KEY (approver_id) REFERENCES Employees (eid),
    FOREIGN KEY (room, floor) REFERENCES MeetingRooms(room, floor) ON DELETE CASCADE,
    PRIMARY KEY (room, floor, date, time)
);

--TRIGGER: Check capacity
--TRIGGER: When create a booking, insert booker into
CREATE TABLE Participates (
    eid INTEGER ,
    room INTEGER,
    floor INTEGER,
    date DATE,
    time TIME CONSTRAINT _c_onTheHour CHECK (EXTRACT(MINUTE FROM time) = 0 AND EXTRACT(SECOND FROM time) = 0 AND EXTRACT(milliseconds FROM time) = 0),
    CONSTRAINT _c_noShadowClones UNIQUE(eid, date, time),
    PRIMARY KEY (eid, room, floor, date, time),
    FOREIGN KEY (room, floor, date, time) REFERENCES Bookings (room, floor, date, time) ON DELETE CASCADE
);

CREATE TABLE Temp_Contact_Tracing (
    eid INTEGER PRIMARY KEY,
    FOREIGN KEY (eid) REFERENCES Employees (eid)
);
