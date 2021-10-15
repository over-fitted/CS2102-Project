CREATE TRIGGER _t_employee_has_contact
AFTER INSERT ON Employees
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION employee_has_contact();


CREATE OR REPLACE FUNCTION employee_has_contact()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        (SELECT * FROM Contact WHERE eid = NEW.eid) IS NULL
    ) THEN
        RAISE EXCEPTION 'Employee has no contact information';
    ELSE
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;