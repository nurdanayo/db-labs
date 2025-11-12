-- Laboratory Work 2: Advanced DDL (Data Definition Language)
-- OBJECTIVE:
-- Practice creating databases, tablespaces, tables, altering and dropping tables in PostgreSQL.
-- ============================================================

-- ============================================================
-- PART 1. DATABASE AND TABLESPACE CREATION
-- ============================================================

-- 1.1 Create Databases
CREATE DATABASE university_main
    WITH OWNER = CURRENT_USER
    TEMPLATE = template0
    ENCODING = 'UTF8';

CREATE DATABASE university_archive
    WITH CONNECTION LIMIT = 50
    TEMPLATE = template0;

CREATE DATABASE university_test
    WITH CONNECTION LIMIT = 10
    IS_TEMPLATE = true;

-- 1.2 Create Tablespaces
CREATE TABLESPACE student_data LOCATION '/data/students';
CREATE TABLESPACE course_data OWNER CURRENT_USER LOCATION '/data/courses';

CREATE DATABASE university_distributed
    TABLESPACE = student_data
    ENCODING = 'LATIN9';


-- ============================================================
-- PART 2. TABLE CREATION
-- ============================================================

-- Students table
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone CHAR(15),
    date_of_birth DATE,
    enrollment_date DATE,
    gpa NUMERIC(4,2),
    is_active BOOLEAN,
    graduation_year SMALLINT
);

-- Professors table
CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    office_number VARCHAR(20),
    hire_date DATE,
    salary NUMERIC(10,2),
    is_tenured BOOLEAN,
    years_experience INTEGER
);

-- Courses table
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code CHAR(8),
    course_title VARCHAR(100),
    description TEXT,
    credits SMALLINT,
    max_enrollment INTEGER,
    course_fee NUMERIC(8,2),
    is_online BOOLEAN,
    created_at TIMESTAMP
);


-- ============================================================
-- PART 3. ALTER TABLE COMMANDS
-- ============================================================

-- 3.1 Alter students
ALTER TABLE students
ADD COLUMN middle_name VARCHAR(30),
ADD COLUMN student_status VARCHAR(20) DEFAULT 'ACTIVE',
ALTER COLUMN phone TYPE VARCHAR(20),
ALTER COLUMN gpa SET DEFAULT 0.00;

-- 3.2 Alter professors
ALTER TABLE professors
ADD COLUMN department_code CHAR(5),
ADD COLUMN research_area TEXT,
ALTER COLUMN years_experience TYPE SMALLINT,
ALTER COLUMN is_tenured SET DEFAULT false,
ADD COLUMN last_promotion_date DATE;

-- 3.3 Alter courses
ALTER TABLE courses
ADD COLUMN prerequisite_course_id INTEGER,
ADD COLUMN difficulty_level SMALLINT,
ALTER COLUMN course_code TYPE VARCHAR(10),
ALTER COLUMN credits SET DEFAULT 3,
ADD COLUMN lab_required BOOLEAN DEFAULT false;


-- ============================================================
-- PART 4. ADDITIONAL TABLES AND RELATIONSHIPS
-- ============================================================

-- Departments table
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100),
    department_code CHAR(5),
    building VARCHAR(50),
    phone VARCHAR(15),
    budget NUMERIC(12,2),
    established_year INTEGER
);

-- Library books
CREATE TABLE library_books (
    book_id SERIAL PRIMARY KEY,
    isbn CHAR(13),
    title VARCHAR(200),
    author VARCHAR(100),
    publisher VARCHAR(100),
    publication_date DATE,
    price NUMERIC(7,2),
    is_available BOOLEAN,
    acquisition_timestamp TIMESTAMP
);

-- Student book loans
CREATE TABLE student_book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_id INTEGER,
    book_id INTEGER,
    loan_date DATE,
    due_date DATE,
    return_date DATE,
    fine_amount NUMERIC(6,2),
    loan_status VARCHAR(20)
);

-- Grade scale
CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),
    min_percentage DECIMAL(4,1),
    max_percentage DECIMAL(4,1),
    gpa_points DECIMAL(3,2)
);

-- Semester calendar
CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INTEGER,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMPTZ,
    is_current BOOLEAN
);


-- ============================================================
-- PART 5. DROP, RECREATE, AND BACKUP OPERATIONS
-- ============================================================

-- Drop some tables safely
DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

-- Recreate grade_scale with additional column
CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),
    min_percentage DECIMAL(4,1),
    max_percentage DECIMAL(4,1),
    gpa_points DECIMAL(3,2),
    description TEXT
);

-- Drop and recreate semester_calendar with CASCADE
DROP TABLE IF EXISTS semester_calendar CASCADE;

CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INTEGER,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMPTZ,
    is_current BOOLEAN
);

-- Drop and recreate databases
DROP DATABASE IF EXISTS university_test;
DROP DATABASE IF EXISTS university_distributed;

CREATE DATABASE university_backup TEMPLATE university_main;

-- ============================================================
-- END OF LAB 2
-- ============================================================
