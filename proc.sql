/* # TRIGGERS & TRIGGER FUNCTIONS # */

/* ## Enforcing data integrity ## */
/* ## Note: All triggers here are initially deferred. ## */

-- ### All Employees must have at least one contact ###

-- #### Enforcing at insertion into Employees #### 
CREATE OR REPLACE FUNCTION _tf_employeeHasContact_insertEmployee()
RETURNS TRIGGER AS $$
DECLARE 
    number INTEGER := 0;
BEGIN 
    SELECT COUNT(*) INTO number
    FROM Contact c
    WHERE NEW.eid = c.eid;
    IF (number = 0) THEN 
        RAISE NOTICE 'Employee has no contact, insert blocked';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER _t_employeeHasContact_insertEmployee
AFTER INSERT ON Employees
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION _tf_employeeHasContact_insertEmployee();

-- #### Enforcing at removal from Contact
CREATE OR REPLACE FUNCTION _tf_employeeHasContact_removeContact()
RETURNS TRIGGER AS $$
DECLARE 
    number INTEGER := 0;
BEGIN 
    SELECT COUNT(*) INTO number
    FROM Contact c
    WHERE OLD.eid = c.eid
        AND OLD.phone != c.phone;
    IF (number = 0) THEN 
        RAISE NOTICE 'Employee has no contact';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER _t_employeeHasContact_removeContact
BEFORE DELETE ON Contact
FOR EACH ROW EXECUTE FUNCTION _tf_employeeHasContact_removeContact();


-- ### All Bookings must have at least one participant, which is the booker ###
CREATE OR REPLACE FUNCTION _tf_bookingInsertBooker()
RETURNS TRIGGER AS $$
BEGIN 
    INSERT INTO Participates 
    VALUES (
        NEW.booker_id,
        NEW.room,
        NEW.floor,
        NEW.date,
        NEW.time
    );
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER _t_bookingInsertBooker
AFTER INSERT ON Bookings
FOR EACH ROW EXECUTE FUNCTION _tf_bookingInsertBooker();

-- ### A booking cannot have more participants than the stated capacity ###
CREATE OR REPLACE FUNCTION _tf_bookingWithinCapacity()
RETURNS TRIGGER AS $$
DECLARE
    currentCapacity INTEGER;
    capacity INTEGER;
BEGIN 
    SELECT COUNT(*) INTO currentCapacity
    FROM Participates p 
    GROUP BY p.room, p.floor, p.date, p.time;

    SELECT m.capacity INTO capacity
    FROM Meeting_Rooms;

    IF (currentCapacity = capacity) THEN
        RAISE NOTICE 'Meeting booking is full!';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER _t_bookingWithinCapacity
BEFORE INSERT ON Participates
FOR EACH ROW EXECUTE FUNCTION _tf_bookingWithinCapacity();

/* FUNCTIONS */



/* PROCEDURES */