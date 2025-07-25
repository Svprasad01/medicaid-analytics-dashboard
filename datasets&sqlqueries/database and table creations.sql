use molina_healthcare;
-- 1. Members Table
CREATE TABLE IF NOT EXISTS members (
    member_id VARCHAR(10) PRIMARY KEY,
    birth_date DATE,
    gender CHAR(1),
    zip_code VARCHAR(10)
);

-- 2. Enrollment Table
CREATE TABLE IF NOT EXISTS enrollment (
    member_id VARCHAR(10),
    plan_id VARCHAR(10),
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (member_id) REFERENCES members(member_id)
);

-- 3. Claims Table
CREATE TABLE IF NOT EXISTS claims (
    claim_id VARCHAR(12) PRIMARY KEY,
    member_id VARCHAR(10),
    claim_type VARCHAR(20),
    service_date DATE,
    diagnosis_code VARCHAR(10),
    cost DECIMAL(10, 2),
    FOREIGN KEY (member_id) REFERENCES members(member_id)
);

-- 4. Providers Table
CREATE TABLE IF NOT EXISTS providers (
    provider_id VARCHAR(10) PRIMARY KEY,
    contract_type VARCHAR(20),
    specialty VARCHAR(20),
    rate_multiplier DECIMAL(4, 2)
);

-- 5. Encounters Table
CREATE TABLE IF NOT EXISTS encounters (
    encounter_id VARCHAR(12) PRIMARY KEY,
    member_id VARCHAR(10),
    provider_id VARCHAR(10),
    encounter_date DATE,
    er_flag BOOLEAN,
    avoidable_flag BOOLEAN,
    FOREIGN KEY (member_id) REFERENCES members(member_id),
    FOREIGN KEY (provider_id) REFERENCES providers(provider_id)
);


SELECT COUNT(*) AS members_count FROM members;
SELECT COUNT(*) AS enrollment_count FROM enrollment;
SELECT COUNT(*) AS claims_count FROM claims;
SELECT COUNT(*) AS providers_count FROM providers;
SELECT COUNT(*) AS encounters_count FROM encounters;

SELECT COUNT(*) AS bad_enrollments
FROM enrollment e
LEFT JOIN members m ON e.member_id = m.member_id
WHERE m.member_id IS NULL;

-- creating logitidinal member view so we can understand per We want a table that shows each member, for each month they were enrolled, and the total cost by claim type (e.g., Inpatient, Pharmacy)

create or replace view member_claims_monthly as
select 
 member_id,
 date_format(service_date,'%Y-%m') as claim_month,
 claim_type,
 sum(cost) as total_cost
from claims 
group by member_id,claim_month,claim_type;

SELECT * FROM member_claims_monthly LIMIT 10;

-- creating member_month view so that we can understand enrollemets in everymonth for each memberid

CREATE OR REPLACE VIEW member_months AS
SELECT
    e.member_id,
    DATE_FORMAT(DATE_ADD(e.start_date, INTERVAL s.seq MONTH), '%Y-%m') AS member_month
FROM enrollment e
JOIN (
    SELECT 0 AS seq UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
) s
  ON DATE_ADD(e.start_date, INTERVAL s.seq MONTH) <= e.end_date;

SELECT * FROM member_months LIMIT 10;






SELECT * FROM member_claims_monthly LIMIT 5;
SELECT DISTINCT member_month FROM member_months ORDER BY member_month LIMIT 5;
SELECT DISTINCT claim_month FROM member_claims_monthly ORDER BY claim_month LIMIT 5;
SELECT
    m.member_id,
    m.member_month,
    c.claim_month,
    c.claim_type,
    c.total_cost
FROM member_months m
LEFT JOIN member_claims_monthly c
    ON m.member_id = c.member_id
    AND m.member_month = c.claim_month
WHERE c.claim_type IS NOT NULL
LIMIT 10;


SELECT
    m.member_month,
    c.claim_type,
    COUNT(DISTINCT m.member_id) AS member_count,
    SUM(COALESCE(c.total_cost, 0)) AS total_cost,
    SUM(COALESCE(c.total_cost, 0)) / COUNT(DISTINCT m.member_id) AS pmpm
FROM member_months m
JOIN member_claims_monthly c
  ON m.member_id = c.member_id
  AND m.member_month = c.claim_month
GROUP BY m.member_month, c.claim_type
ORDER BY m.member_month;

SELECT * FROM pmpm_view ORDER BY member_month, claim_type;
SELECT *
FROM pmpm_view
WHERE claim_type IS NOT NULL AND claim_type != 'No Claims'
ORDER BY member_month, claim_type;


-- using cte Longitudinal Member View Using CTEs + Window Functions CTEs to break the logic into stages Window functions to calculate running totals, first/last visits, and flags

WITH base_claims AS (
    SELECT
        c.member_id,
        c.claim_type,
        c.service_date,
        c.cost,
        ROW_NUMBER() OVER (PARTITION BY c.member_id ORDER BY c.service_date) AS claim_seq
    FROM claims c
),

encounter_details AS (
    SELECT
        e.member_id,
        e.encounter_date,
        e.er_flag,
        e.avoidable_flag,
        p.specialty,
        p.contract_type,
        p.rate_multiplier,
        ROW_NUMBER() OVER (PARTITION BY e.member_id ORDER BY e.encounter_date DESC) AS most_recent_flag
    FROM encounters e
    JOIN providers p ON e.provider_id = p.provider_id
),

enrollment_months AS (
    SELECT
        e.member_id,
        DATE_FORMAT(DATE_ADD(e.start_date, INTERVAL seq MONTH), '%Y-%m') AS member_month
    FROM enrollment e
    JOIN (
        SELECT 0 AS seq UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
        UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
        UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
    ) s ON DATE_ADD(e.start_date, INTERVAL s.seq MONTH) <= e.end_date
)

SELECT
    em.member_id,
    em.member_month,
    bc.claim_type,
    bc.cost,
    bc.claim_seq,
    ed.specialty,
    ed.contract_type,
    ed.rate_multiplier,
    ed.er_flag,
    ed.avoidable_flag,
    ed.most_recent_flag
FROM enrollment_months em
LEFT JOIN base_claims bc
    ON em.member_id = bc.member_id AND DATE_FORMAT(bc.service_date, '%Y-%m') = em.member_month
LEFT JOIN encounter_details ed
    ON em.member_id = ed.member_id AND DATE_FORMAT(ed.encounter_date, '%Y-%m') = em.member_month;



-- er spike detection to view high aviodable er costs 
SELECT
    member_month,
    COUNT(*) AS avoidable_er_visits,
    ROUND(SUM(COALESCE(cost, 0)), 2) AS total_avoidable_cost
FROM longitudinal_view  -- replace with your actual view name
WHERE er_flag = 1 AND avoidable_flag = 1
GROUP BY member_month
ORDER BY member_month;

-- to print all view tables in the schema 

SHOW FULL TABLES IN molina_healthcare WHERE TABLE_TYPE = 'VIEW';

CREATE OR REPLACE VIEW longitudinal_member_view AS
WITH base_claims AS (
    SELECT
        c.member_id,
        c.claim_type,
        c.service_date,
        c.cost,
        ROW_NUMBER() OVER (PARTITION BY c.member_id ORDER BY c.service_date) AS claim_seq
    FROM claims c
),

encounter_details AS (
    SELECT
        e.member_id,
        e.encounter_date,
        e.er_flag,
        e.avoidable_flag,
        p.specialty,
        p.contract_type,
        p.rate_multiplier,
        ROW_NUMBER() OVER (PARTITION BY e.member_id ORDER BY e.encounter_date DESC) AS most_recent_flag
    FROM encounters e
    JOIN providers p ON e.provider_id = p.provider_id
),

enrollment_months AS (
    SELECT
        e.member_id,
        DATE_FORMAT(DATE_ADD(e.start_date, INTERVAL s.seq MONTH), '%Y-%m') AS member_month
    FROM enrollment e
    JOIN (
        SELECT 0 AS seq UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
        UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
        UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
    ) s ON DATE_ADD(e.start_date, INTERVAL s.seq MONTH) <= e.end_date
)

SELECT
    em.member_id,
    em.member_month,
    bc.claim_type,
    bc.cost,
    bc.claim_seq,
    ed.specialty,
    ed.contract_type,
    ed.rate_multiplier,
    ed.er_flag,
    ed.avoidable_flag,
    ed.most_recent_flag
FROM enrollment_months em
LEFT JOIN base_claims bc
    ON em.member_id = bc.member_id AND DATE_FORMAT(bc.service_date, '%Y-%m') = em.member_month
LEFT JOIN encounter_details ed
    ON em.member_id = ed.member_id AND DATE_FORMAT(ed.encounter_date, '%Y-%m') = em.member_month;

