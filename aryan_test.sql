BEGIN;

-- Testing Non_compliance
/*
CALL declare_health(1, '2018-04-01'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(1, '2018-04-02'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(2, '2018-04-01'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(2, '2018-04-02'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(3, '2018-04-01'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(3, '2018-04-02'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(4, '2018-04-01'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(4, '2018-04-02'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(5, '2018-04-01'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(5, '2018-04-02'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(6, '2018-04-01'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(6, '2018-04-02'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(7, '2018-04-01'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(8, '2018-04-01'::DATE, 35.6, '12:00:00'::TIME);
CALL declare_health(9, '2018-04-01'::DATE, 35.6, '12:00:00'::TIME);

SELECT * FROM _f_non_compliance('2018-04-01'::date, '2018-04-02'::date);
*/

-- Testing Fever Event 
/*
CALL declare_health(9, '2018-04-01'::DATE, 37.6, '12:00:00'::TIME);
*/


/*
CALL approve_meeting()
*/

END;