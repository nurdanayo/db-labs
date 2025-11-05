-- Создание таблицы сотрудников
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    salary DECIMAL(10, 2)
);

-- Вставка данных в таблицу сотрудников
INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
(1, 'Jane Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 50000),
(5, 'Tom Brown', NULL, 45000);

-- Создание таблицы отделов
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50)
);

-- Вставка данных в таблицу отделов
INSERT INTO departments (dept_id, dept_name) VALUES
(101, 'HR'),
(102, 'Finance'),
(103, 'Engineering');

-- Соединение сотрудников с отделами (INNER JOIN)
SELECT e.emp_name, d.dept_name
FROM employees e
         INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Соединение сотрудников с отделами (LEFT JOIN)
SELECT e.emp_name, d.dept_name
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- Использование CROSS JOIN для всех сочетаний сотрудников и проектов
SELECT e.emp_name, p.project_name
FROM employees e
         CROSS JOIN projects p;

-- Использование NATURAL JOIN
SELECT e.emp_name, d.dept_name
FROM employees e
         NATURAL INNER JOIN departments d;

-- Использование FULL JOIN для всех сочетаний
SELECT e.emp_name, d.dept_name
FROM employees e
         FULL JOIN departments d ON e.dept_id = d.dept_id;

-- Обновление местоположения отдела
UPDATE departments
SET location = 'Building A'
WHERE dept_id = 101;

-- Фильтрация данных с WHERE
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
         LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';

-- Группировка данных по количеству сотрудников в отделах
SELECT dept_id, COUNT(*) AS num_employees
FROM employees
GROUP BY dept_id;

-- Удаление сотрудника
DELETE FROM employees
WHERE emp_id = 5;

-- Сортировка по зарплате
SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;
