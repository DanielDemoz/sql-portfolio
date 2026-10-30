-- =============================================
-- ADVANCED WINDOW FUNCTIONS
-- Demonstrating analytical SQL capabilities
-- =============================================
-- Author: Daniel S. Demoz
-- Complexity: 🟠 Advanced
-- =============================================

-- =============================================
-- 1. RANKING FUNCTIONS
-- =============================================

-- Example 1: Rank students by GPA within each department
-- Use Case: Dean's List, scholarships, honors
SELECT 
    s.student_id,
    s.first_name || ' ' || s.last_name AS student_name,
    d.department_name,
    s.gpa,
    RANK() OVER (PARTITION BY d.department_id ORDER BY s.gpa DESC) AS gpa_rank,
    DENSE_RANK() OVER (PARTITION BY d.department_id ORDER BY s.gpa DESC) AS gpa_dense_rank,
    NTILE(4) OVER (PARTITION BY d.department_id ORDER BY s.gpa DESC) AS quartile,
    PERCENT_RANK() OVER (PARTITION BY d.department_id ORDER BY s.gpa DESC) AS percentile_rank
FROM students s
JOIN departments d ON s.major_department_id = d.department_id
WHERE s.is_active = TRUE AND s.gpa IS NOT NULL
ORDER BY d.department_name, gpa_rank;

-- Example 2: Identify top 3 students in each department
WITH ranked_students AS (
    SELECT 
        s.student_id,
        s.first_name || ' ' || s.last_name AS student_name,
        d.department_name,
        s.gpa,
        RANK() OVER (PARTITION BY d.department_id ORDER BY s.gpa DESC) AS rank
    FROM students s
    JOIN departments d ON s.major_department_id = d.department_id
    WHERE s.is_active = TRUE
)
SELECT *
FROM ranked_students
WHERE rank <= 3
ORDER BY department_name, rank;

-- =============================================
-- 2. RUNNING TOTALS & CUMULATIVE AGGREGATES
-- =============================================

-- Example 3: Running total of student enrollments by semester
-- Use Case: Enrollment growth tracking
WITH semester_enrollments AS (
    SELECT 
        cs.semester,
        cs.year,
        COUNT(DISTINCT e.student_id) AS new_enrollments
    FROM enrollments e
    JOIN course_schedules cs ON e.schedule_id = cs.schedule_id
    WHERE e.status = 'Enrolled'
    GROUP BY cs.semester, cs.year
)
SELECT 
    semester,
    year,
    new_enrollments,
    SUM(new_enrollments) OVER (
        ORDER BY year, 
        CASE semester 
            WHEN 'Spring' THEN 1 
            WHEN 'Summer' THEN 2 
            WHEN 'Fall' THEN 3 
        END
    ) AS cumulative_enrollments,
    AVG(new_enrollments) OVER (
        ORDER BY year, 
        CASE semester 
            WHEN 'Spring' THEN 1 
            WHEN 'Summer' THEN 2 
            WHEN 'Fall' THEN 3 
        END
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_3_semesters
FROM semester_enrollments
ORDER BY year, 
    CASE semester 
        WHEN 'Spring' THEN 1 
        WHEN 'Summer' THEN 2 
        WHEN 'Fall' THEN 3 
    END;

-- =============================================
-- 3. LEAD & LAG FUNCTIONS
-- =============================================

-- Example 4: Track GPA changes over time
-- Use Case: Monitor student academic progress
WITH student_gpas_by_semester AS (
    SELECT 
        e.student_id,
        cs.semester,
        cs.year,
        AVG(e.grade_points) AS semester_gpa
    FROM enrollments e
    JOIN course_schedules cs ON e.schedule_id = cs.schedule_id
    WHERE e.status = 'Completed' AND e.grade_points IS NOT NULL
    GROUP BY e.student_id, cs.semester, cs.year
)
SELECT 
    student_id,
    semester,
    year,
    ROUND(semester_gpa, 2) AS current_gpa,
    ROUND(LAG(semester_gpa) OVER (PARTITION BY student_id ORDER BY year, semester), 2) AS previous_gpa,
    ROUND(semester_gpa - LAG(semester_gpa) OVER (PARTITION BY student_id ORDER BY year, semester), 2) AS gpa_change,
    CASE 
        WHEN semester_gpa > LAG(semester_gpa) OVER (PARTITION BY student_id ORDER BY year, semester) 
        THEN 'Improving'
        WHEN semester_gpa < LAG(semester_gpa) OVER (PARTITION BY student_id ORDER BY year, semester) 
        THEN 'Declining'
        ELSE 'Stable'
    END AS trend
FROM student_gpas_by_semester
ORDER BY student_id, year, semester;

-- Example 5: Find students who improved their GPA for 3 consecutive semesters
WITH gpa_trends AS (
    SELECT 
        e.student_id,
        cs.semester,
        cs.year,
        AVG(e.grade_points) AS semester_gpa,
        LAG(AVG(e.grade_points), 1) OVER (PARTITION BY e.student_id ORDER BY cs.year, cs.semester) AS prev_gpa_1,
        LAG(AVG(e.grade_points), 2) OVER (PARTITION BY e.student_id ORDER BY cs.year, cs.semester) AS prev_gpa_2
    FROM enrollments e
    JOIN course_schedules cs ON e.schedule_id = cs.schedule_id
    WHERE e.status = 'Completed' AND e.grade_points IS NOT NULL
    GROUP BY e.student_id, cs.semester, cs.year
)
SELECT 
    gt.student_id,
    s.first_name || ' ' || s.last_name AS student_name,
    gt.semester,
    gt.year,
    ROUND(gt.semester_gpa, 2) AS current_gpa,
    ROUND(gt.prev_gpa_1, 2) AS prev_semester_1,
    ROUND(gt.prev_gpa_2, 2) AS prev_semester_2
FROM gpa_trends gt
JOIN students s ON gt.student_id = s.student_id
WHERE gt.semester_gpa > gt.prev_gpa_1 
  AND gt.prev_gpa_1 > gt.prev_gpa_2
ORDER BY gt.student_id, gt.year, gt.semester;

-- =============================================
-- 4. FIRST_VALUE & LAST_VALUE
-- =============================================

-- Example 6: Compare each student's current GPA to their best and worst semesters
WITH semester_performance AS (
    SELECT 
        e.student_id,
        cs.semester,
        cs.year,
        AVG(e.grade_points) AS semester_gpa
    FROM enrollments e
    JOIN course_schedules cs ON e.schedule_id = cs.schedule_id
    WHERE e.status = 'Completed' AND e.grade_points IS NOT NULL
    GROUP BY e.student_id, cs.semester, cs.year
)
SELECT 
    sp.student_id,
    s.first_name || ' ' || s.last_name AS student_name,
    sp.semester,
    sp.year,
    ROUND(sp.semester_gpa, 2) AS current_gpa,
    ROUND(FIRST_VALUE(sp.semester_gpa) OVER (
        PARTITION BY sp.student_id 
        ORDER BY sp.semester_gpa DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ), 2) AS best_semester_gpa,
    ROUND(FIRST_VALUE(sp.semester_gpa) OVER (
        PARTITION BY sp.student_id 
        ORDER BY sp.semester_gpa ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ), 2) AS worst_semester_gpa,
    ROUND(sp.semester_gpa - FIRST_VALUE(sp.semester_gpa) OVER (
        PARTITION BY sp.student_id 
        ORDER BY sp.semester_gpa ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ), 2) AS improvement_from_worst
FROM semester_performance sp
JOIN students s ON sp.student_id = s.student_id
ORDER BY sp.student_id, sp.year DESC, sp.semester;

-- =============================================
-- 5. COMPLEX AGGREGATIONS WITH WINDOW FUNCTIONS
-- =============================================

-- Example 7: Course enrollment analysis with percentiles
-- Use Case: Identify popular vs unpopular courses
-- PostgreSQL does not allow PERCENTILE_CONT ... OVER (), so the percentiles
-- are computed once in a CTE and joined to every row.
WITH active_schedules AS (
    SELECT cs.*, c.course_code, c.course_name, c.max_enrollment
    FROM course_schedules cs
    JOIN courses c ON cs.course_id = c.course_id
    WHERE c.is_active = TRUE
),
cutoffs AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY enrollment_count) AS p25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY enrollment_count) AS p50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY enrollment_count) AS p75
    FROM active_schedules
)
SELECT 
    a.course_code,
    a.course_name,
    a.semester,
    a.year,
    a.enrollment_count,
    a.max_enrollment,
    ROUND(100.0 * a.enrollment_count / a.max_enrollment, 2) AS fill_rate,
    ROUND(AVG(a.enrollment_count) OVER (PARTITION BY a.course_id), 2) AS avg_enrollment_this_course,
    ROUND(AVG(a.enrollment_count) OVER (), 2) AS avg_enrollment_all_courses,
    k.p50 AS median_enrollment,
    NTILE(10) OVER (ORDER BY a.enrollment_count) AS decile,
    CASE 
        WHEN a.enrollment_count >= k.p75 THEN 'High Demand'
        WHEN a.enrollment_count >= k.p25 THEN 'Moderate Demand'
        ELSE 'Low Demand'
    END AS demand_category
FROM active_schedules a
CROSS JOIN cutoffs k
ORDER BY a.enrollment_count DESC;

-- =============================================
-- 6. MOVING AVERAGES & TREND ANALYSIS
-- =============================================

-- Example 8: Instructor performance trends
-- Use Case: Teaching effectiveness over time
WITH instructor_semester_stats AS (
    SELECT 
        i.instructor_id,
        i.first_name || ' ' || i.last_name AS instructor_name,
        cs.semester,
        cs.year,
        COUNT(DISTINCT cs.schedule_id) AS courses_taught,
        AVG(e.grade_points) AS avg_grade_given,
        SUM(cs.enrollment_count) AS total_students,
        ROUND(AVG(e.attendance_percentage), 2) AS avg_attendance
    FROM instructors i
    JOIN course_schedules cs ON i.instructor_id = cs.instructor_id
    LEFT JOIN enrollments e ON cs.schedule_id = e.schedule_id AND e.status = 'Completed'
    GROUP BY i.instructor_id, i.first_name, i.last_name, cs.semester, cs.year
)
SELECT 
    instructor_id,
    instructor_name,
    semester,
    year,
    courses_taught,
    ROUND(avg_grade_given, 2) AS avg_grade,
    total_students,
    avg_attendance,
    -- 3-semester moving average
    ROUND(AVG(avg_grade_given) OVER (
        PARTITION BY instructor_id 
        ORDER BY year, semester 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_grade_3sem,
    -- Trend: is performance improving?
    CASE 
        WHEN avg_grade_given > LAG(avg_grade_given, 1) OVER (PARTITION BY instructor_id ORDER BY year, semester)
             AND LAG(avg_grade_given, 1) OVER (PARTITION BY instructor_id ORDER BY year, semester) > 
                 LAG(avg_grade_given, 2) OVER (PARTITION BY instructor_id ORDER BY year, semester)
        THEN 'Improving'
        WHEN avg_grade_given < LAG(avg_grade_given, 1) OVER (PARTITION BY instructor_id ORDER BY year, semester)
             AND LAG(avg_grade_given, 1) OVER (PARTITION BY instructor_id ORDER BY year, semester) < 
                 LAG(avg_grade_given, 2) OVER (PARTITION BY instructor_id ORDER BY year, semester)
        THEN 'Declining'
        ELSE 'Stable'
    END AS performance_trend
FROM instructor_semester_stats
ORDER BY instructor_id, year DESC, semester;

-- =============================================
-- 7. ADVANCED: GAPS AND ISLANDS
-- =============================================

-- Example 9: Find consecutive semesters with high enrollment
-- Use Case: Identify sustained course popularity
WITH enrollment_with_row_num AS (
    SELECT 
        cs.course_id,
        c.course_code,
        c.course_name,
        cs.semester,
        cs.year,
        cs.enrollment_count,
        c.max_enrollment,
        CASE WHEN cs.enrollment_count >= 0.8 * c.max_enrollment THEN 1 ELSE 0 END AS is_high_enrollment,
        ROW_NUMBER() OVER (PARTITION BY cs.course_id ORDER BY cs.year, cs.semester) AS rn
    FROM course_schedules cs
    JOIN courses c ON cs.course_id = c.course_id
),
high_enrollment_groups AS (
    SELECT 
        *,
        rn - ROW_NUMBER() OVER (PARTITION BY course_id, is_high_enrollment ORDER BY year, semester) AS grp
    FROM enrollment_with_row_num
    WHERE is_high_enrollment = 1
)
SELECT 
    course_code,
    course_name,
    MIN(semester || ' ' || year) AS start_period,
    MAX(semester || ' ' || year) AS end_period,
    COUNT(*) AS consecutive_semesters
FROM high_enrollment_groups
GROUP BY course_id, course_code, course_name, grp
HAVING COUNT(*) >= 3  -- At least 3 consecutive semesters
ORDER BY consecutive_semesters DESC, course_code;

-- =============================================
-- KEY TAKEAWAYS
-- =============================================

/*
Window Functions Demonstrated:
1. RANK() / DENSE_RANK() / NTILE() - Ranking within groups
2. SUM() / AVG() OVER - Running aggregates
3. LAG() / LEAD() - Access previous/next row values
4. FIRST_VALUE() / LAST_VALUE() - Frame boundary values
5. PERCENTILE_CONT() - Statistical distributions
6. Moving averages with ROWS BETWEEN
7. Gaps and Islands pattern

Business Applications:
- Student performance tracking
- Course demand analysis
- Instructor effectiveness
- Enrollment trends
- Academic interventions
- Resource allocation

Performance Tips:
- Use appropriate window frame (ROWS vs RANGE)
- Consider indexing partition and order columns
- Materialize complex CTEs if reused
- Test with EXPLAIN ANALYZE
*/

