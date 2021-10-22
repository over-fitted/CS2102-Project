BEGIN;
SELECT * FROM _f_non_compliance('2017-03-01'::date, '2017-03-03'::date);
END;