CREATE OR REPLACE FUNCTION view_booking_report(IN startDate DATE, IN eid INT)
RETURNS TABLE(floor INT, room INT, date DATE, startTime TIMESTAMP, isApproved BOOLEAN)
AS $$    
BEGIN
    return QUERY SELECT b.floor, b.room, b.date, b.time, b.approver_id IS NOT NULL approved
    FROM Bookings b
    WHERE b.booker_id = eid
    AND b.date > startDate
    ORDER BY b.date;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_future_meeting(IN startDate DATE, IN employee_id INT)
RETURNS TABLE(floor INT, room INT, date DATE, startTime TIMESTAMP, eid INT)
AS $$    
BEGIN
    return QUERY SELECT p.floor, p.room, p.date, p.time, p.eid
    FROM Participates p NATURAL JOIN Bookings b
    WHERE b.approver_id IS NOT NULL
    AND p.eid = employee_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_manager_report(IN startDate DATE, IN employee_id INT)
RETURNS TABLE(floor INT, room INT, date DATE, startTime TIMESTAMP, eid INT)
AS $$
DECLARE managed_did INT;
BEGIN
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
    AND b.date > startDate
    ORDER BY b.date ASC, b.time asc;
END;
$$ LANGUAGE plpgsql;