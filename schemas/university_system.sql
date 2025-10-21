-- =============================================
-- UNIVERSITY COURSE MANAGEMENT SYSTEM
-- Database Schema Design
-- =============================================
-- Author: Daniel S. Demoz
-- Description: Complete database for managing students, courses, 
--              instructors, enrollments, and academic records
-- =============================================

-- Drop existing tables (in reverse order of dependencies)
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS course_prerequisites CASCADE;
DROP TABLE IF EXISTS course_schedules CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS instructors CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS rooms CASCADE;

-- =============================================
-- CORE ENTITIES
-- =============================================

-- Departments
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_code VARCHAR(10) UNIQUE NOT NULL,
    department_name VARCHAR(100) NOT NULL,
    building VARCHAR(50),
    office_room VARCHAR(20),
    chair_name VARCHAR(100),
    budget DECIMAL(12, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Students
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    admission_date DATE NOT NULL,
    major_department_id INTEGER REFERENCES departments(department_id),
    academic_standing VARCHAR(20) CHECK (academic_standing IN ('Good', 'Probation', 'Suspended', 'Dean''s List')),
    gpa DECIMAL(3, 2) CHECK (gpa >= 0.00 AND gpa <= 4.00),
    total_credits INTEGER DEFAULT 0,
    graduation_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Instructors
CREATE TABLE instructors (
    instructor_id SERIAL PRIMARY KEY,
    employee_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    department_id INTEGER REFERENCES departments(department_id),
    title VARCHAR(50) CHECK (title IN ('Professor', 'Associate Professor', 'Assistant Professor', 'Lecturer', 'Adjunct')),
    hire_date DATE NOT NULL,
    office_room VARCHAR(20),
    office_hours VARCHAR(100),
    salary DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Rooms
CREATE TABLE rooms (
    room_id SERIAL PRIMARY KEY,
    building VARCHAR(50) NOT NULL,
    room_number VARCHAR(20) NOT NULL,
    capacity INTEGER NOT NULL,
    room_type VARCHAR(30) CHECK (room_type IN ('Lecture Hall', 'Lab', 'Seminar Room', 'Auditorium')),
    has_projector BOOLEAN DEFAULT FALSE,
    has_computers BOOLEAN DEFAULT FALSE,
    is_accessible BOOLEAN DEFAULT TRUE,
    UNIQUE(building, room_number)
);

-- Courses
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code VARCHAR(20) UNIQUE NOT NULL,
    course_name VARCHAR(100) NOT NULL,
    department_id INTEGER REFERENCES departments(department_id),
    credits INTEGER NOT NULL CHECK (credits > 0),
    description TEXT,
    level VARCHAR(20) CHECK (level IN ('Undergraduate', 'Graduate')),
    max_enrollment INTEGER DEFAULT 30,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Course Prerequisites
CREATE TABLE course_prerequisites (
    prerequisite_id SERIAL PRIMARY KEY,
    course_id INTEGER REFERENCES courses(course_id),
    prerequisite_course_id INTEGER REFERENCES courses(course_id),
    minimum_grade VARCHAR(2) DEFAULT 'D',
    is_corequisite BOOLEAN DEFAULT FALSE,
    UNIQUE(course_id, prerequisite_course_id),
    CHECK (course_id != prerequisite_course_id)
);

-- Course Schedules
CREATE TABLE course_schedules (
    schedule_id SERIAL PRIMARY KEY,
    course_id INTEGER REFERENCES courses(course_id),
    instructor_id INTEGER REFERENCES instructors(instructor_id),
    room_id INTEGER REFERENCES rooms(room_id),
    semester VARCHAR(20) NOT NULL,
    year INTEGER NOT NULL,
    day_of_week VARCHAR(10) CHECK (day_of_week IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    section_number VARCHAR(10) NOT NULL,
    enrollment_count INTEGER DEFAULT 0,
    waitlist_count INTEGER DEFAULT 0,
    CHECK (end_time > start_time),
    UNIQUE(room_id, day_of_week, start_time, semester, year)
);

-- Enrollments
CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(student_id),
    schedule_id INTEGER REFERENCES course_schedules(schedule_id),
    enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('Enrolled', 'Waitlisted', 'Dropped', 'Completed')) DEFAULT 'Enrolled',
    grade VARCHAR(2) CHECK (grade IN ('A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F', 'W', 'I', 'P')),
    grade_points DECIMAL(3, 2),
    attendance_percentage DECIMAL(5, 2),
    UNIQUE(student_id, schedule_id)
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Student indexes
CREATE INDEX idx_students_email ON students(email);
CREATE INDEX idx_students_major ON students(major_department_id);
CREATE INDEX idx_students_active ON students(is_active);
CREATE INDEX idx_students_gpa ON students(gpa DESC);

-- Course indexes
CREATE INDEX idx_courses_department ON courses(department_id);
CREATE INDEX idx_courses_code ON courses(course_code);
CREATE INDEX idx_courses_active ON courses(is_active);

-- Schedule indexes
CREATE INDEX idx_schedules_semester ON course_schedules(semester, year);
CREATE INDEX idx_schedules_instructor ON course_schedules(instructor_id);
CREATE INDEX idx_schedules_course ON course_schedules(course_id);

-- Enrollment indexes
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_schedule ON enrollments(schedule_id);
CREATE INDEX idx_enrollments_status ON enrollments(status);

-- =============================================
-- VIEWS FOR COMMON QUERIES
-- =============================================

-- View: Current course offerings
CREATE OR REPLACE VIEW current_course_offerings AS
SELECT 
    cs.schedule_id,
    c.course_code,
    c.course_name,
    c.credits,
    i.first_name || ' ' || i.last_name AS instructor_name,
    r.building || ' ' || r.room_number AS location,
    cs.day_of_week,
    cs.start_time,
    cs.end_time,
    cs.semester,
    cs.year,
    cs.section_number,
    cs.enrollment_count,
    c.max_enrollment,
    (c.max_enrollment - cs.enrollment_count) AS seats_available
FROM course_schedules cs
JOIN courses c ON cs.course_id = c.course_id
JOIN instructors i ON cs.instructor_id = i.instructor_id
JOIN rooms r ON cs.room_id = r.room_id
WHERE c.is_active = TRUE;

-- View: Student transcripts
CREATE OR REPLACE VIEW student_transcripts AS
SELECT 
    s.student_id,
    s.student_number,
    s.first_name || ' ' || s.last_name AS student_name,
    c.course_code,
    c.course_name,
    c.credits,
    cs.semester,
    cs.year,
    e.grade,
    e.grade_points,
    i.first_name || ' ' || i.last_name AS instructor_name
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN course_schedules cs ON e.schedule_id = cs.schedule_id
JOIN courses c ON cs.course_id = c.course_id
JOIN instructors i ON cs.instructor_id = i.instructor_id
WHERE e.status = 'Completed'
ORDER BY s.student_id, cs.year DESC, cs.semester;

-- View: Instructor workload
CREATE OR REPLACE VIEW instructor_workload AS
SELECT 
    i.instructor_id,
    i.first_name || ' ' || i.last_name AS instructor_name,
    i.title,
    d.department_name,
    cs.semester,
    cs.year,
    COUNT(DISTINCT cs.schedule_id) AS courses_teaching,
    SUM(cs.enrollment_count) AS total_students,
    SUM(c.credits) AS total_credits
FROM instructors i
LEFT JOIN course_schedules cs ON i.instructor_id = cs.instructor_id
LEFT JOIN courses c ON cs.course_id = c.course_id
LEFT JOIN departments d ON i.department_id = d.department_id
WHERE i.is_active = TRUE
GROUP BY i.instructor_id, i.first_name, i.last_name, i.title, d.department_name, cs.semester, cs.year;

-- =============================================
-- FUNCTIONS
-- =============================================

-- Function: Calculate GPA for a student
CREATE OR REPLACE FUNCTION calculate_student_gpa(p_student_id INTEGER)
RETURNS DECIMAL(3, 2) AS $$
DECLARE
    v_gpa DECIMAL(3, 2);
BEGIN
    SELECT 
        ROUND(
            SUM(e.grade_points * c.credits) / NULLIF(SUM(c.credits), 0),
            2
        )
    INTO v_gpa
    FROM enrollments e
    JOIN course_schedules cs ON e.schedule_id = cs.schedule_id
    JOIN courses c ON cs.course_id = c.course_id
    WHERE e.student_id = p_student_id
    AND e.status = 'Completed'
    AND e.grade NOT IN ('W', 'I', 'P');
    
    RETURN COALESCE(v_gpa, 0.00);
END;
$$ LANGUAGE plpgsql;

-- Function: Check if student has prerequisites
CREATE OR REPLACE FUNCTION check_prerequisites(p_student_id INTEGER, p_course_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    v_missing_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_missing_count
    FROM course_prerequisites cp
    WHERE cp.course_id = p_course_id
    AND NOT EXISTS (
        SELECT 1
        FROM enrollments e
        JOIN course_schedules cs ON e.schedule_id = cs.schedule_id
        WHERE e.student_id = p_student_id
        AND cs.course_id = cp.prerequisite_course_id
        AND e.status = 'Completed'
        AND e.grade >= cp.minimum_grade
    );
    
    RETURN v_missing_count = 0;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- SAMPLE DATA COMMENTS
-- =============================================

-- To populate with sample data, run generate_sample_data.sql
-- This schema supports:
--   - Student registration and enrollment management
--   - Course catalog and scheduling
--   - Prerequisite tracking
--   - Academic record keeping
--   - Instructor workload management
--   - Room utilization tracking

-- =============================================
-- GRANTS (adjust as needed for your environment)
-- =============================================

-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO student_role;
-- GRANT SELECT, INSERT, UPDATE ON enrollments TO registration_role;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;

