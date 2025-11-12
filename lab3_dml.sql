-- Laboratory Work 3: Advanced DML (Data Manipulation Language)
-- OBJECTIVE:
-- Practice using INSERT, UPDATE, DELETE, RETURNING, CASE, and subqueries in PostgreSQL.
-- ============================================================

-- ============================================================
-- PART 1. DATABASE SETUP
-- ============================================================

CREATE DATABASE advanced_lab;
\c advanced_lab;

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INTEGER DEFAULT 40000,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);


-- ============================================================
-- PART 2. INSERT STATEMENTS
-- ============================================================

-- Insert employees
INSERT INTO employees (first_name, last_name, department)
VALUES ('John', 'Smith', 'IT');

INSERT INTO employees (first_name, last_name)
VALUES ('Anna', 'Keller');

INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('HR', 60000, 1),
       ('Sales', 120000, 2),
       ('IT', 90000, 3);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Mark', 'Lee', 'Finance', 50000 * 1.1, CURRENT_DATE);

-- Insert from SELECT
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';


-- ============================================================
-- PART 3. UPDATE STATEMENTS
-- ============================================================

-- 3.1 Simple salary increase
UPDATE employees SET salary = salary * 1.10;

-- 3.2 Conditional update
UPDATE employees 
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

-- 3.3 CASE expression in UPDATE
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

-- 3.4 Subquery update
UPDATE departments
SET budget = (SELECT AVG(salary) * 1.2 FROM employees e WHERE e.department = departments.dept_name);

-- 3.5 Multi-column update
UPDATE employees
SET salary = salary * 1.15, status = 'Promoted'
WHERE department = 'Sales';


-- ============================================================
-- PART 4. DELETE STATEMENTS
-- ============================================================

-- 4.1 Basic delete
DELETE FROM employees WHERE status = 'Terminated';

-- 4.2 Delete with subquery
DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT department FROM employees WHERE department IS NOT NULL
);

-- 4.3 DELETE with RETURNING
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;


-- ============================================================
-- PART 5. RETURNING CLAUSE AND CONDITIONAL INSERTS
-- ============================================================

-- 5.1 INSERT RETURNING
INSERT INTO employees (first_name, last_name, department)
VALUES ('Sara', 'Brown', 'Design')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- 5.2 UPDATE RETURNING
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

-- 5.3 Conditional INSERT (if not exists)
INSERT INTO employees (first_name, last_name, department)
SELECT 'David', 'Kim', 'Sales'
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name='David' AND last_name='Kim'
);

-- 5.4 UPDATE with CASE + subquery
UPDATE employees
SET salary = salary * CASE
    WHEN (SELECT budget FROM departments WHERE dept_name = employees.department) > 100000 THEN 1.10
    ELSE 1.05
END;

-- 5.5 Archive inactive employees
CREATE TABLE employee_archive AS TABLE employees WITH NO DATA;
INSERT INTO employee_archive SELECT * FROM employees WHERE status = 'Inactive';
DELETE FROM employees WHERE status = 'Inactive';


-- ============================================================
-- PART 6. ADDITIONAL PRACTICAL TASK (GYM DATABASE)
-- ============================================================

-- Tables
CREATE TABLE members (
    member_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    membership_type VARCHAR(20),
    monthly_fee NUMERIC(6,2),
    join_date DATE,
    status VARCHAR(20),
    renewal_date DATE
);

CREATE TABLE gym_classes (
    class_id SERIAL PRIMARY KEY,
    class_name VARCHAR(50),
    instructor_name VARCHAR(50),
    max_capacity INTEGER,
    current_enrolled INTEGER,
    class_fee NUMERIC(6,2)
);

CREATE TABLE class_bookings (
    booking_id SERIAL PRIMARY KEY,
    member_id INTEGER,
    class_id INTEGER,
    booking_date DATE,
    attendance_status VARCHAR(20),
    payment_received BOOLEAN
);

-- Inserts
INSERT INTO members (full_name, membership_type, monthly_fee, join_date, status)
VALUES ('Sarah Johnson', 'Premium', 89.99, CURRENT_DATE, 'Active'),
       ('Mike Chen', 'Basic', 49.99, CURRENT_DATE, 'Active');

INSERT INTO gym_classes (class_name, instructor_name, max_capacity, current_enrolled, class_fee)
VALUES ('Advanced Yoga', 'Lisa Martinez', 25, 0, 15.00 * 1.3);

INSERT INTO members (full_name, membership_type, monthly_fee, join_date, status)
VALUES ('Trial Member', NULL, NULL, CURRENT_DATE, 'Trial');

-- Updates
UPDATE members SET monthly_fee = monthly_fee * 1.12 WHERE membership_type = 'Premium';

UPDATE members
SET status = CASE
    WHEN monthly_fee > 70 THEN 'VIP'
    WHEN monthly_fee BETWEEN 40 AND 70 THEN 'Regular'
    ELSE 'Basic'
END;

UPDATE gym_classes SET current_enrolled = current_enrolled + 1 WHERE class_id = 1;

UPDATE members
SET monthly_fee = monthly_fee / 2, membership_type = 'Suspended'
WHERE status = 'Inactive';

-- Deletes
DELETE FROM members
WHERE status = 'Cancelled' AND join_date < '2023-01-01';

DELETE FROM gym_classes
WHERE current_enrolled = 0 AND class_fee > 50;

DELETE FROM class_bookings
WHERE attendance_status = 'No-Show'
RETURNING booking_id, member_id;

-- Advanced updates/deletes
UPDATE members
SET renewal_date = NULL
WHERE membership_type IS NULL
RETURNING member_id, full_name;

DELETE FROM class_bookings
WHERE member_id IN (
    SELECT member_id FROM members WHERE status != 'Active'
);

-- ============================================================
-- END OF LAB 3 AND GYM TASK
-- ============================================================
