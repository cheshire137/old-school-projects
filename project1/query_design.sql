SELECT CASE WHEN lclass = class OR
                 class = 'TS' OR
                 (class = 'S' AND lclass = 'C')
            THEN lname
            ELSE NULL
       END AS lname,
       CASE WHEN fclass = class OR
                 class = 'TS' OR
                 (class = 'S' AND fclass = 'C')
            THEN fname
            ELSE NULL
       END AS fname,
       CASE WHEN jclass = class OR
                 class = 'TS' OR
                 (class = 'S' AND fclass = 'C')
            THEN jurisdiction
            ELSE NULL
       END AS jurisdiction
FROM clients,
     (
       SELECT UPPER(class) AS class
       FROM user_levels
       WHERE name = 'marek'
     ) AS user_level
WHERE amount BETWEEN 14000 AND 20000;
