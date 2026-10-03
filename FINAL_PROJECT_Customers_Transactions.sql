use finalproject;

USE finalproject;

-- Необязательно, один раз: индексы ускоряют JOIN (без них запросы могут идти минутами)
-- CREATE INDEX idx_cust_id   ON customers(Id_client);
-- CREATE INDEX idx_tx_client ON transactions(ID_client);
-- CREATE INDEX idx_tx_date   ON transactions(date_new);

SET @date_from = '2015-06-01';
SET @date_to   = '2016-06-01';   -- не включительно





#1
WITH tx AS (
    SELECT * FROM transactions
    WHERE date_new >= @date_from AND date_new < @date_to
),
client_stats AS (
    SELECT ID_client,
           COUNT(DISTINCT date_new) AS active_months,
           COUNT(DISTINCT Id_check) AS operations_cnt,
           COUNT(*)                 AS positions_cnt,
           SUM(Sum_payment)         AS total_sum
    FROM tx
    GROUP BY ID_client
)
SELECT cs.ID_client, c.Gender, c.Age, cs.active_months,
       cs.operations_cnt, cs.positions_cnt,
       ROUND(cs.total_sum, 2)                     AS total_sum,
       ROUND(cs.total_sum / cs.operations_cnt, 2) AS avg_check,
       ROUND(cs.total_sum / 12, 2)                AS avg_month_sum
FROM client_stats cs
LEFT JOIN customers c ON c.Id_client = cs.ID_client
WHERE cs.active_months = 12
ORDER BY total_sum DESC;



#2; 2.1-2.4 
WITH tx AS (
    SELECT * FROM transactions
    WHERE date_new >= @date_from AND date_new < @date_to
),
monthly AS (
    SELECT DATE_FORMAT(date_new, '%Y-%m') AS month_,
           SUM(Sum_payment)               AS month_sum,
           COUNT(DISTINCT Id_check)       AS operations_cnt,
           COUNT(DISTINCT ID_client)      AS clients_cnt
    FROM tx
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
)
SELECT month_,
       ROUND(month_sum, 2)                                          AS month_sum,
       ROUND(month_sum / operations_cnt, 2)                         AS avg_check,                    -- 2.1
       operations_cnt,                                                                               -- 2.2
       ROUND(operations_cnt / clients_cnt, 2)                       AS avg_operations_per_client,
       ROUND(AVG(operations_cnt) OVER (), 2)                        AS avg_operations_per_month_year,
       clients_cnt,                                                                                  -- 2.3
       ROUND(AVG(clients_cnt) OVER (), 2)                           AS avg_clients_per_month_year,
       ROUND(100 * operations_cnt / SUM(operations_cnt) OVER (), 2) AS share_operations_pct,         -- 2.4
       ROUND(100 * month_sum      / SUM(month_sum)      OVER (), 2) AS share_sum_pct
FROM monthly
ORDER BY month_;



#2.5
WITH tx AS (
    SELECT DATE_FORMAT(t.date_new, '%Y-%m')           AS month_,
           t.ID_client, t.Id_check, t.Sum_payment,
           COALESCE(NULLIF(TRIM(c.Gender), ''), 'NA') AS gender
    FROM transactions t
    LEFT JOIN customers c ON c.Id_client = t.ID_client
    WHERE t.date_new >= @date_from AND t.date_new < @date_to
),
by_gender AS (
    SELECT month_, gender,
           COUNT(DISTINCT ID_client) AS clients_cnt,
           COUNT(DISTINCT Id_check)  AS operations_cnt,
           SUM(Sum_payment)          AS gender_sum
    FROM tx
    GROUP BY month_, gender
)
SELECT month_, gender,
       clients_cnt,
       ROUND(100 * clients_cnt    / SUM(clients_cnt)    OVER (PARTITION BY month_), 2) AS clients_share_pct,
       operations_cnt,
       ROUND(100 * operations_cnt / SUM(operations_cnt) OVER (PARTITION BY month_), 2) AS operations_share_pct,
       ROUND(gender_sum, 2)                                                            AS gender_sum,
       ROUND(100 * gender_sum     / SUM(gender_sum)     OVER (PARTITION BY month_), 2) AS sum_share_pct
FROM by_gender
ORDER BY month_, gender;



#3.1
WITH tx AS (
    SELECT t.*,
           CASE WHEN c.Age IS NULL THEN 'NA'
                ELSE CONCAT(FLOOR(c.Age/10)*10, '-', FLOOR(c.Age/10)*10 + 9) END AS age_group,
           COALESCE(FLOOR(c.Age/10)*10, 999) AS age_sort
    FROM transactions t
    LEFT JOIN customers c ON c.Id_client = t.ID_client
    WHERE t.date_new >= @date_from AND t.date_new < @date_to
)
SELECT age_group,
       COUNT(DISTINCT ID_client)                                        AS clients_cnt,
       ROUND(SUM(Sum_payment), 2)                                       AS total_sum,
       COUNT(DISTINCT Id_check)                                         AS operations_cnt,
       ROUND(100 * SUM(Sum_payment) / SUM(SUM(Sum_payment)) OVER (), 2) AS sum_share_pct,
       ROUND(100 * COUNT(DISTINCT Id_check)
                 / SUM(COUNT(DISTINCT Id_check)) OVER (), 2)            AS operations_share_pct
FROM tx
GROUP BY age_group, age_sort
ORDER BY age_sort;




#3.2
WITH tx AS (
    SELECT t.*,
           CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS quarter_,
           CASE WHEN c.Age IS NULL THEN 'NA'
                ELSE CONCAT(FLOOR(c.Age/10)*10, '-', FLOOR(c.Age/10)*10 + 9) END AS age_group,
           COALESCE(FLOOR(c.Age/10)*10, 999) AS age_sort
    FROM transactions t
    LEFT JOIN customers c ON c.Id_client = t.ID_client
    WHERE t.date_new >= @date_from AND t.date_new < @date_to
),
q AS (
    SELECT quarter_, age_group, age_sort,
           COUNT(DISTINCT date_new)  AS months_in_quarter,
           COUNT(DISTINCT ID_client) AS clients_cnt,
           COUNT(DISTINCT Id_check)  AS operations_cnt,
           SUM(Sum_payment)          AS q_sum
    FROM tx
    GROUP BY quarter_, age_group, age_sort
)
SELECT quarter_, age_group, clients_cnt, operations_cnt,
       ROUND(q_sum, 2)                              AS q_sum,
       ROUND(q_sum / operations_cnt, 2)             AS avg_check,
       ROUND(operations_cnt / clients_cnt, 2)       AS avg_operations_per_client,
       ROUND(q_sum / clients_cnt, 2)                AS avg_sum_per_client,
       ROUND(q_sum / months_in_quarter, 2)          AS avg_month_sum,
       ROUND(operations_cnt / months_in_quarter, 2) AS avg_month_operations,
       ROUND(100 * q_sum          / SUM(q_sum)          OVER (PARTITION BY quarter_), 2) AS sum_share_pct,
       ROUND(100 * operations_cnt / SUM(operations_cnt) OVER (PARTITION BY quarter_), 2) AS operations_share_pct,
       ROUND(100 * clients_cnt    / SUM(clients_cnt)    OVER (PARTITION BY quarter_), 2) AS clients_share_pct
FROM q
ORDER BY quarter_, age_sort;





#If we need from period of all 13 month including June 2016
USE finalproject;

SET @date_from = '2015-06-01';
SET @date_to   = '2016-06-01';   -- включительно


#1
WITH tx AS (
    SELECT * FROM transactions
    WHERE date_new >= @date_from AND date_new <= @date_to
),
client_stats AS (
    SELECT ID_client,
           COUNT(DISTINCT date_new) AS active_months,
           COUNT(*)                 AS operations_cnt,
           COUNT(DISTINCT Id_check) AS checks_cnt,
           SUM(Sum_payment)         AS total_sum
    FROM tx
    GROUP BY ID_client
)
SELECT cs.ID_client, c.Gender, c.Age, cs.active_months,
       cs.operations_cnt, cs.checks_cnt,
       ROUND(cs.total_sum, 2)                 AS total_sum,
       ROUND(cs.total_sum / cs.checks_cnt, 2) AS avg_check,
       ROUND(cs.total_sum / 13, 2)            AS avg_month_sum
FROM client_stats cs
LEFT JOIN customers c ON c.Id_client = cs.ID_client
WHERE cs.active_months = 13
ORDER BY total_sum DESC;



#2.1-2.4
WITH tx AS (
    SELECT * FROM transactions
    WHERE date_new >= @date_from AND date_new <= @date_to
),
monthly AS (
    SELECT DATE_FORMAT(date_new, '%Y-%m') AS month_,
           SUM(Sum_payment)               AS month_sum,
           COUNT(*)                       AS operations_cnt,
           COUNT(DISTINCT Id_check)       AS checks_cnt,
           COUNT(DISTINCT ID_client)      AS clients_cnt
    FROM tx
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
)
SELECT month_,
       ROUND(month_sum, 2)                                          AS month_sum,
       ROUND(month_sum / checks_cnt, 2)                             AS avg_check,                    -- 2.1
       operations_cnt,                                                                               -- 2.2
       ROUND(operations_cnt / clients_cnt, 2)                       AS avg_operations_per_client,
       ROUND(AVG(operations_cnt) OVER (), 2)                        AS avg_operations_per_month_year,
       clients_cnt,                                                                                  -- 2.3
       ROUND(AVG(clients_cnt) OVER (), 2)                           AS avg_clients_per_month_year,
       ROUND(100 * operations_cnt / SUM(operations_cnt) OVER (), 2) AS share_operations_pct,         -- 2.4
       ROUND(100 * month_sum      / SUM(month_sum)      OVER (), 2) AS share_sum_pct
FROM monthly
ORDER BY month_;



#2.5 
WITH tx AS (
    SELECT DATE_FORMAT(t.date_new, '%Y-%m')           AS month_,
           t.ID_client, t.Sum_payment,
           COALESCE(NULLIF(TRIM(c.Gender), ''), 'NA') AS gender
    FROM transactions t
    LEFT JOIN customers c ON c.Id_client = t.ID_client
    WHERE t.date_new >= @date_from AND t.date_new <= @date_to
),
by_gender AS (
    SELECT month_, gender,
           COUNT(DISTINCT ID_client) AS clients_cnt,
           COUNT(*)                  AS operations_cnt,
           SUM(Sum_payment)          AS gender_sum
    FROM tx
    GROUP BY month_, gender
)
SELECT month_, gender,
       clients_cnt,
       ROUND(100 * clients_cnt    / SUM(clients_cnt)    OVER (PARTITION BY month_), 2) AS clients_share_pct,
       operations_cnt,
       ROUND(100 * operations_cnt / SUM(operations_cnt) OVER (PARTITION BY month_), 2) AS operations_share_pct,
       ROUND(gender_sum, 2)                                                            AS gender_sum,
       ROUND(100 * gender_sum     / SUM(gender_sum)     OVER (PARTITION BY month_), 2) AS sum_share_pct
FROM by_gender
ORDER BY month_, gender;




#3.1 
WITH tx AS (
    SELECT t.*,
           CASE WHEN c.Age IS NULL THEN 'NA'
                ELSE CONCAT(FLOOR(c.Age/10)*10, '-', FLOOR(c.Age/10)*10 + 9) END AS age_group,
           COALESCE(FLOOR(c.Age/10)*10, 999) AS age_sort
    FROM transactions t
    LEFT JOIN customers c ON c.Id_client = t.ID_client
    WHERE t.date_new >= @date_from AND t.date_new <= @date_to
)
SELECT age_group,
       COUNT(DISTINCT ID_client)                                        AS clients_cnt,
       ROUND(SUM(Sum_payment), 2)                                       AS total_sum,
       COUNT(*)                                                         AS operations_cnt,
       ROUND(100 * SUM(Sum_payment) / SUM(SUM(Sum_payment)) OVER (), 2) AS sum_share_pct,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)                 AS operations_share_pct
FROM tx
GROUP BY age_group, age_sort
ORDER BY age_sort;



#3.2
WITH tx AS (
    SELECT t.*,
           CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS quarter_,
           CASE WHEN c.Age IS NULL THEN 'NA'
                ELSE CONCAT(FLOOR(c.Age/10)*10, '-', FLOOR(c.Age/10)*10 + 9) END AS age_group,
           COALESCE(FLOOR(c.Age/10)*10, 999) AS age_sort
    FROM transactions t
    LEFT JOIN customers c ON c.Id_client = t.ID_client
    WHERE t.date_new >= @date_from AND t.date_new <= @date_to
),
q AS (
    SELECT quarter_, age_group, age_sort,
           COUNT(DISTINCT date_new)  AS months_in_quarter,
           COUNT(DISTINCT ID_client) AS clients_cnt,
           COUNT(*)                  AS operations_cnt,
           COUNT(DISTINCT Id_check)  AS checks_cnt,
           SUM(Sum_payment)          AS q_sum
    FROM tx
    GROUP BY quarter_, age_group, age_sort
)
SELECT quarter_, age_group, clients_cnt, operations_cnt,
       ROUND(q_sum, 2)                              AS q_sum,
       ROUND(q_sum / checks_cnt, 2)                 AS avg_check,
       ROUND(operations_cnt / clients_cnt, 2)       AS avg_operations_per_client,
       ROUND(q_sum / clients_cnt, 2)                AS avg_sum_per_client,
       ROUND(q_sum / months_in_quarter, 2)          AS avg_month_sum,
       ROUND(operations_cnt / months_in_quarter, 2) AS avg_month_operations,
       ROUND(100 * q_sum          / SUM(q_sum)          OVER (PARTITION BY quarter_), 2) AS sum_share_pct,
       ROUND(100 * operations_cnt / SUM(operations_cnt) OVER (PARTITION BY quarter_), 2) AS operations_share_pct,
       ROUND(100 * clients_cnt    / SUM(clients_cnt)    OVER (PARTITION BY quarter_), 2) AS clients_share_pct
FROM q
ORDER BY quarter_, age_sort;