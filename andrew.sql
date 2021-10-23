CREATE OR REPLACE FUNCTION view_booking_report(IN startDate DATE, IN eid INT)
RETURNS TABLE(floor INT, room INT, date DATE, startTime TIME, isApproved BOOLEAN)
AS $$    
BEGIN
    return QUERY SELECT b.floor, b.room, b.date, b.time, b.approver_id IS NOT NULL approved
    FROM Bookings b
    WHERE b.booker_id = eid
    AND b.date >= startDate
    ORDER BY b.date ASC, b.time ASC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_future_meeting(IN startDate DATE, IN employee_id INT)
RETURNS TABLE(floor INT, room INT, date DATE, startTime TIME, eid INT)
AS $$    
BEGIN
    return QUERY SELECT p.floor, p.room, p.date, p.time, p.eid
    FROM Participates p NATURAL JOIN Bookings b
    WHERE b.approver_id IS NOT NULL
    AND p.eid = employee_id
    AND p.date >= startDate
    ORDER BY b.date ASC, b.time ASC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_manager_report(IN startDate DATE, IN employee_id INT)
RETURNS TABLE(floor INT, room INT, date DATE, startTime TIME, eid INT)
AS $$
DECLARE managed_did INT;
BEGIN
    IF (SELECT e.etype <> 'Manager' FROM Employees e WHERE e.eid = employee_id) 
    THEN RETURN;
    END IF;    
    SELECT e.did INTO managed_did
    FROM Employees e
    WHERE e.eid = employee_id;

    RETURN QUERY SELECT b.floor, b.room, b.date, b.time, b.booker_id
    FROM Bookings b
    WHERE b.booker_id IN (
        SELECT e.eid
        FROM Employees e
        WHERE e.did = managed_did
    )
    AND b.approver_id IS NULL
    AND b.date >= startDate
    ORDER BY b.date ASC, b.time asc;
END;
$$ LANGUAGE plpgsql;