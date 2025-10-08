------------------------------------------------------------
-- Lab 4: SQL Queries, Functions and Operators
-- сделано для практики по SQL, проверяю разные функции
-- KBTU | Database Systems | Lab 4
------------------------------------------------------------

-- если уже запускала раньше, удаляю таблицы чтобы не было конфликтов
DROP TABLE IF EXISTS assignments CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;

-- создаю таблицы
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary NUMERIC(10,2),
    hire_date DATE,
    manager_id INTEGER,
    email VARCHAR(100)
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    budget NUMERIC(12,2),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20)
);

CREATE TABLE assignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    project_id INTEGER REFERENCES projects(project_id),
    hours_worked NUMERIC(5,1),
    assignment_date DATE
);

-- добавляю тестовые данные (из задания)
INSERT INTO employees (first_name, last_name, department, salary, hire_date, manager_id, email) VALUES
('John','Smith','IT',75000,'2020-01-15',NULL,'john.smith@company.com'),
('Sarah','Johnson','IT',65000,'2020-03-20',1,'sarah.j@company.com'),
('Michael','Brown','Sales',55000,'2019-06-10',NULL,'mbrown@company.com'),
('Emily','Davis','HR',60000,'2021-02-01',NULL,'emily.d@company.com'),
('Robert','Wilson','IT',70000,'2020-08-15',1,NULL),
('Lisa','Anderson','Sales',58000,'2021-05-20',3,'lisa.a@company.com');

INSERT INTO projects (project_name, budget, start_date, end_date, status) VALUES
('Website Redesign',150000,'2024-01-01','2024-06-30','Active'),
('CRM Implementation',200000,'2024-02-15','2024-12-31','Active'),
('Marketing Campaign',80000,'2024-03-01','2024-05-31','Completed'),
('Database Migration',120000,'2024-01-10',NULL,'Active');

INSERT INTO assignments (employee_id, project_id, hours_worked, assignment_date) VALUES
(1,1,120.5,'2024-01-15'),
(2,1,95.0,'2024-01-20'),
(1,4,80.0,'2024-02-01'),
(3,3,60.0,'2024-03-05'),
(5,2,110.0,'2024-02-20'),
(6,3,75.5,'2024-03-10');

------------------------------------------------------------
-- PART 1: Basic SELECT Queries
------------------------------------------------------------

-- 1.1 просто вывожу всех сотрудников с ФИО, департаментом и зарплатой
SELECT first_name || ' ' || last_name AS full_name, department, salary
FROM employees;

-- 1.2 уникальные отделы (чтобы не дублировались)
SELECT DISTINCT department FROM employees;

-- 1.3 проекты + категории бюджета через CASE
SELECT project_name, budget,
    CASE
        WHEN budget > 150000 THEN 'Large'
        WHEN budget BETWEEN 100000 AND 150000 THEN 'Medium'
        ELSE 'Small'
    END AS budget_category
FROM projects;

-- 1.4 показываю email, если NULL то текст
SELECT first_name || ' ' || last_name AS full_name,
       COALESCE(email, 'No email provided') AS email
FROM employees;

------------------------------------------------------------
-- PART 2: WHERE и сравнения
------------------------------------------------------------

-- 2.1 сотрудники, нанятые после 2020
SELECT * FROM employees
WHERE hire_date > '2020-01-01';

-- 2.2 зарплата между 60к и 70к
SELECT * FROM employees
WHERE salary BETWEEN 60000 AND 70000;

-- 2.3 фамилии, начинающиеся с S или J
SELECT * FROM employees
WHERE last_name LIKE 'S%' OR last_name LIKE 'J%';

-- 2.4 у кого есть менеджер и они из IT
SELECT * FROM employees
WHERE manager_id IS NOT NULL AND department = 'IT';

------------------------------------------------------------
-- PART 3: Строковые и математические функции
------------------------------------------------------------

-- 3.1 делаю имена заглавными, считаю длину фамилии и беру первые 3 буквы email
SELECT UPPER(first_name || ' ' || last_name) AS employee_name,
       LENGTH(last_name) AS last_name_length,
       SUBSTRING(email FROM 1 FOR 3) AS email_prefix
FROM employees;

-- 3.2 считаю годовую и месячную зарплату + 10% прибавку
SELECT first_name || ' ' || last_name AS full_name,
       salary AS annual_salary,
       ROUND(salary / 12, 2) AS monthly_salary,
       salary * 1.10 AS salary_with_raise
FROM employees;

-- 3.3 форматирую строку с проектом
SELECT FORMAT('Project: %s - Budget: $%s - Status: %s', project_name, budget, status) AS project_info
FROM projects;

-- 3.4 считаю, сколько лет работает сотрудник
SELECT first_name || ' ' || last_name AS full_name,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS years_with_company
FROM employees;

------------------------------------------------------------
-- PART 4: Агрегаты и GROUP BY
------------------------------------------------------------

-- 4.1 средняя зарплата по отделам
SELECT department, ROUND(AVG(salary),2) AS avg_salary
FROM employees
GROUP BY department;

-- 4.2 суммарные часы по каждому проекту
SELECT p.project_name, SUM(a.hours_worked) AS total_hours
FROM assignments a
JOIN projects p ON a.project_id = p.project_id
GROUP BY p.project_name;

-- 4.3 количество сотрудников в каждом отделе (>1)
SELECT department, COUNT(*) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(*) > 1;

-- 4.4 максимум, минимум и сумма зарплат
SELECT MAX(salary) AS max_salary,
       MIN(salary) AS min_salary,
       SUM(salary) AS total_payroll
FROM employees;

------------------------------------------------------------
-- PART 5: Set Operations
------------------------------------------------------------

-- 5.1 UNION — зарплата > 65к или нанят после 2020
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE salary > 65000
UNION
SELECT employee_id, first_name || ' ' || last_name, salary
FROM employees
WHERE hire_date > '2020-01-01';

-- 5.2 INTERSECT — сотрудники из IT и с з/п > 65к
SELECT first_name || ' ' || last_name AS full_name, department, salary
FROM employees
WHERE department = 'IT'
INTERSECT
SELECT first_name || ' ' || last_name, department, salary
FROM employees
WHERE salary > 65000;

-- 5.3 EXCEPT — кто не привязан к проектам
SELECT employee_id, first_name || ' ' || last_name AS full_name
FROM employees
EXCEPT
SELECT DISTINCT e.employee_id, e.first_name || ' ' || e.last_name
FROM employees e
JOIN assignments a ON e.employee_id = a.employee_id;

------------------------------------------------------------
-- PART 6: Подзапросы
------------------------------------------------------------

-- 6.1 сотрудники с хотя бы одним assignment
SELECT e.*
FROM employees e
WHERE EXISTS (
    SELECT 1 FROM assignments a
    WHERE a.employee_id = e.employee_id
);

-- 6.2 сотрудники, работающие над активными проектами
SELECT e.*
FROM employees e
WHERE e.employee_id IN (
    SELECT a.employee_id
    FROM assignments a
    JOIN projects p ON a.project_id = p.project_id
    WHERE p.status = 'Active'
);

-- 6.3 зарплата выше, чем у кого-то из Sales
SELECT first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE salary > ANY (
    SELECT salary FROM employees WHERE department = 'Sales'
);

------------------------------------------------------------
-- PART 7: Сложные запросы
------------------------------------------------------------

-- 7.1 среднее время и ранг по зарплате в отделе
SELECT e.first_name || ' ' || e.last_name AS employee_name,
       e.department,
       ROUND(AVG(a.hours_worked),2) AS avg_hours,
       RANK() OVER (PARTITION BY e.department ORDER BY e.salary DESC) AS salary_rank
FROM employees e
LEFT JOIN assignments a ON e.employee_id = a.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.department, e.salary;

-- 7.2 проекты с суммой часов > 150
SELECT p.project_name,
       SUM(a.hours_worked) AS total_hours,
       COUNT(DISTINCT a.employee_id) AS employee_count
FROM assignments a
JOIN projects p ON a.project_id = p.project_id
GROUP BY p.project_name
HAVING SUM(a.hours_worked) > 150;

-- 7.3 отчёт по отделам
SELECT department,
       COUNT(*) AS total_employees,
       ROUND(AVG(salary),2) AS avg_salary,
       (SELECT first_name || ' ' || last_name
        FROM employees e2
        WHERE e2.department = e1.department
        ORDER BY salary DESC LIMIT 1) AS highest_paid
FROM employees e1
GROUP BY department;

------------------------------------------------------------
-- конец файла, вроде всё работает :)
------------------------------------------------------------

