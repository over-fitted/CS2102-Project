BEGIN;
INSERT into Bookings values (1, 6, '2017-04-14', '02:00:00',7);
CALL _p_approve_meeting(1, 6, '2017-04-14'::date,'02:00:00'::time,'03:00:00'::time, 5);
END;