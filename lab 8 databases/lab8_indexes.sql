-------------------------------------------------------
-- Laboratory Work 8: Indexes - CREATE INDEX script
-------------------------------------------------------

-- Part 2: Basic Indexes

-- Exercise 2.1: index on salary
CREATE INDEX emp_salary_idx ON employees(salary);

-- Exercise 2.2: index on foreign key dept_id
CREATE INDEX emp_dept_idx ON employees(dept_id);


-- Part 3: Multicolumn Indexes

-- Exercise 3.1: index on (dept_id, salary)
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

-- Exercise 3.2: index on (salary, dept_id)
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);


-- Part 4: Unique Indexes

-- Exercise 4.1: unique index on email
CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);


-- Part 5: Indexes and Sorting

-- Exercise 5.1: index for ORDER BY salary DESC
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

-- Exercise 5.2: index on budget with NULLS FIRST
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);


-- Part 6: Indexes on Expressions

-- Exercise 6.1: index on LOWER(emp_name)
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

-- Exercise 6.2: index on EXTRACT(YEAR FROM hire_date)
CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));


-- Part 8: Practical Scenarios

-- Exercise 8.1: partial index for salary > 50000
CREATE INDEX emp_salary_filter_idx
ON employees(salary)
WHERE salary > 50000;

-- Exercise 8.2: partial index for high-budget projects
CREATE INDEX proj_high_budget_idx
ON projects(budget)
WHERE budget > 80000;


-- Part 9: Index Types Comparison

-- Exercise 9.1: HASH index on dept_name
CREATE INDEX dept_name_hash_idx
ON departments USING HASH (dept_name);

-- Exercise 9.2: B-tree and Hash indexes on proj_name

-- B-tree index
CREATE INDEX proj_name_btree_idx ON projects(proj_name);

-- Hash index
CREATE INDEX proj_name_hash_idx
ON projects USING HASH (proj_name);
