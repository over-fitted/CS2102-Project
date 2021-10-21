BEGIN;
INSERT into Bookings values (1, 6, '2017-04-14', '02:00:00',7);
INSERT into Bookings values (1, 6, '2017-04-14', '03:00:00',7);
CALL _p_approve_meeting(6, 1, '2017-04-14'::date,'02:00:00'::time,'03:00:00'::time, 5);
SELECT * FROM Bookings;
END;