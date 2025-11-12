-- Laboratory Work 5: Database Constraints
-- OBJECTIVE:
-- Practice defining and enforcing data constraints (CHECK, NOT NULL, UNIQUE, PK, FK, ON DELETE) in PostgreSQL.
-- ============================================================

-- ============================================================
-- PART 1. CHECK CONSTRAINTS
-- ============================================================

CREATE TABLE employees (
  employee_id INT,
  first_name TEXT,
  last_name TEXT,
  age INT CHECK (age BETWEEN 18 AND 65),
  salary NUMERIC CHECK (salary > 0)
);

CREATE TABLE products_catalog (
  product_id INT,
  product_name TEXT,
  regular_price NUMERIC,
  discount_price NUMERIC,
  CONSTRAINT valid_discount CHECK (
    regular_price > 0 AND discount_price > 0 AND discount_price < regular_price
  )
);

CREATE TABLE bookings (
  booking_id INT,
  check_in_date DATE,
  check_out_date DATE,
  num_guests INT CHECK (num_guests BETWEEN 1 AND 10),
  CHECK (check_out_date > check_in_date)
);


-- ============================================================
-- PART 2. NOT NULL CONSTRAINTS
-- ============================================================

CREATE TABLE customers (
  customer_id INT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  registration_date DATE NOT NULL
);

CREATE TABLE inventory (
  item_id INT NOT NULL,
  item_name TEXT NOT NULL,
  quantity INT NOT NULL CHECK (quantity >= 0),
  unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
  last_updated TIMESTAMP NOT NULL
);


-- ============================================================
-- PART 3. UNIQUE CONSTRAINTS
-- ============================================================

CREATE TABLE users (
  user_id INT,
  username TEXT UNIQUE,
  email TEXT UNIQUE,
  created_at TIMESTAMP
);

CREATE TABLE course_enrollments (
  enrollment_id INT,
  student_id INT,
  course_code TEXT,
  semester TEXT,
  UNIQUE (student_id, course_code, semester)
);

ALTER TABLE users 
  ADD CONSTRAINT unique_username UNIQUE (username),
  ADD CONSTRAINT unique_email UNIQUE (email);


-- ============================================================
-- PART 4. PRIMARY AND FOREIGN KEYS
-- ============================================================

CREATE TABLE departments (
  dept_id INT PRIMARY KEY,
  dept_name TEXT NOT NULL,
  location TEXT
);

CREATE TABLE student_courses (
  student_id INT,
  course_id INT,
  enrollment_date DATE,
  grade TEXT,
  PRIMARY KEY (student_id, course_id)
);

CREATE TABLE employees_dept (
  emp_id INT PRIMARY KEY,
  emp_name TEXT NOT NULL,
  dept_id INT REFERENCES departments(dept_id),
  hire_date DATE
);


-- ============================================================
-- PART 5. ON DELETE BEHAVIOR AND CASCADE EXAMPLES
-- ============================================================

CREATE TABLE authors (
  author_id INT PRIMARY KEY,
  author_name TEXT NOT NULL,
  country TEXT
);

CREATE TABLE publishers (
  publisher_id INT PRIMARY KEY,
  publisher_name TEXT NOT NULL,
  city TEXT
);

CREATE TABLE books (
  book_id INT PRIMARY KEY,
  title TEXT NOT NULL,
  author_id INT REFERENCES authors,
  publisher_id INT REFERENCES publishers,
  publication_year INT,
  isbn TEXT UNIQUE
);

CREATE TABLE categories (
  category_id INT PRIMARY KEY,
  category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
  product_id INT PRIMARY KEY,
  product_name TEXT NOT NULL,
  category_id INT REFERENCES categories ON DELETE RESTRICT
);

CREATE TABLE orders (
  order_id INT PRIMARY KEY,
  order_date DATE NOT NULL
);

CREATE TABLE order_items (
  item_id INT PRIMARY KEY,
  order_id INT REFERENCES orders ON DELETE CASCADE,
  product_id INT REFERENCES products_fk,
  quantity INT CHECK (quantity > 0)
);


-- ============================================================
-- PART 6. PRACTICAL EXAMPLE: E-COMMERCE SCHEMA
-- ============================================================

CREATE TABLE customers_ecom (
  customer_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  registration_date DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE products_ecom (
  product_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC NOT NULL CHECK (price >= 0),
  stock_quantity INT NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE orders_ecom (
  order_id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES customers_ecom ON DELETE CASCADE,
  order_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_amount NUMERIC CHECK (total_amount >= 0),
  status TEXT CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE order_details_ecom (
  order_detail_id SERIAL PRIMARY KEY,
  order_id INT REFERENCES orders_ecom ON DELETE CASCADE,
  product_id INT REFERENCES products_ecom ON DELETE RESTRICT,
  quantity INT CHECK (quantity > 0),
  unit_price NUMERIC NOT NULL CHECK (unit_price >= 0)
);


-- ============================================================
-- ADDITIONAL TASK: ONLINE LEARNING PLATFORM (IN-CLASS TASK #7)
-- ============================================================

-- Categories and Instructors
CREATE TABLE categories (
  category_id INT PRIMARY KEY,
  category_name TEXT UNIQUE NOT NULL,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE instructors (
  instructor_id INT PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  bio TEXT,
  hourly_rate NUMERIC CHECK (hourly_rate BETWEEN 15 AND 500),
  rating NUMERIC CHECK (rating BETWEEN 0.0 AND 5.0),
  total_students INT NOT NULL DEFAULT 0 CHECK (total_students >= 0),
  joined_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Courses
CREATE TABLE courses (
  course_id INT PRIMARY KEY,
  course_title TEXT NOT NULL,
  instructor_id INT NOT NULL REFERENCES instructors ON DELETE RESTRICT,
  category_id INT NOT NULL REFERENCES categories ON DELETE RESTRICT,
  description TEXT NOT NULL,
  level TEXT NOT NULL CHECK (level IN ('beginner','intermediate','advanced','expert')),
  regular_price NUMERIC NOT NULL CHECK (regular_price BETWEEN 9.99 AND 999.99),
  sale_price NUMERIC CHECK (sale_price < regular_price AND sale_price >= 0),
  duration_hours NUMERIC NOT NULL CHECK (duration_hours BETWEEN 0.5 AND 200),
  max_students INT CHECK (max_students BETWEEN 10 AND 10000),
  enrollment_count INT NOT NULL DEFAULT 0 CHECK (enrollment_count >= 0),
  is_published BOOLEAN NOT NULL DEFAULT FALSE,
  created_date DATE NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (course_title, instructor_id)
);

-- Students
CREATE TABLE students (
  student_id INT PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
  account_balance NUMERIC NOT NULL DEFAULT 0,
  total_courses_completed INT NOT NULL DEFAULT 0 CHECK (total_courses_completed >= 0),
  subscription_type TEXT NOT NULL DEFAULT 'free' CHECK (subscription_type IN ('free','monthly','annual','lifetime')),
  CHECK ((CURRENT_DATE - date_of_birth) / 365 >= 13),
  CHECK (registration_date <= CURRENT_DATE)
);

-- Enrollments
CREATE TABLE enrollments (
  student_id INT REFERENCES students ON DELETE CASCADE,
  course_id INT REFERENCES courses ON DELETE RESTRICT,
  enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  price_paid NUMERIC NOT NULL CHECK (price_paid >= 0),
  progress_percentage NUMERIC NOT NULL DEFAULT 0 CHECK (progress_percentage BETWEEN 0 AND 100),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed','dropped','refunded')),
  completion_date DATE,
  certificate_issued BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (student_id, course_id),
  CHECK (NOT(status = 'completed' AND progress_percentage <> 100)),
  CHECK (NOT(certificate_issued = TRUE AND status <> 'completed'))
);

-- ============================================================
-- END OF LAB 5 + IN-CLASS CONSTRAINTS TASK
-- ============================================================
