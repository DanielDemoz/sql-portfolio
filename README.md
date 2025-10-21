# SQL Portfolio - Advanced Queries & Database Design

![SQL](https://img.shields.io/badge/SQL-PostgreSQL%20%7C%20MySQL-blue)
![Database](https://img.shields.io/badge/Database-Design%20%7C%20Optimization-green)

## Live Examples

**Interactive Showcase:** [View Examples](https://danieldemoz.github.io/sql-portfolio/)  
![Demo](https://img.shields.io/badge/Demo-Live-brightgreen)

*An interactive presentation of SQL query results and business analytics for non-technical audiences.*

## Overview

A comprehensive SQL portfolio demonstrating advanced database design, complex queries, optimization techniques, and real-world business analytics use cases. This repository showcases practical SQL skills across multiple database systems and business scenarios.

## What's Inside

### 1. **Database Design Projects**
- University Course Management System
- E-commerce Platform Schema
- Healthcare Patient Records
- Transit System Database (TTC-inspired)

### 2. **Advanced SQL Queries**
- Complex JOINs and subqueries
- Window functions and CTEs
- Recursive queries
- Query optimization techniques

### 3. **Business Analytics**
- Customer segmentation queries
- Sales analytics and reporting
- Time-series analysis
- Cohort analysis

### 4. **Real-World Scenarios**
- Data warehouse design
- ETL processes
- Stored procedures and functions
- Triggers and constraints

## Project Structure

```
sql-portfolio/
├── schemas/
│   ├── university_system.sql
│   ├── ecommerce_platform.sql
│   ├── healthcare_records.sql
│   └── transit_system.sql
├── queries/
│   ├── 01_basic_queries.sql
│   ├── 02_joins_subqueries.sql
│   ├── 03_window_functions.sql
│   ├── 04_cte_recursive.sql
│   └── 05_optimization.sql
├── analytics/
│   ├── customer_analytics.sql
│   ├── sales_reporting.sql
│   ├── cohort_analysis.sql
│   └── funnel_analysis.sql
├── procedures/
│   ├── stored_procedures.sql
│   ├── functions.sql
│   └── triggers.sql
├── sample_data/
│   └── generate_sample_data.sql
└── README.md
```

## Quick Start

### Prerequisites

- PostgreSQL 12+ or MySQL 8+
- SQL client (pgAdmin, MySQL Workbench, DBeaver, etc.)

### Setup

```bash
# Clone the repository
git clone https://github.com/DanielDemoz/sql-portfolio.git
cd sql-portfolio

# Connect to your database
psql -U your_username -d your_database

# Run schema setup (example for university system)
\i schemas/university_system.sql

# Load sample data
\i sample_data/generate_sample_data.sql

# Try sample queries
\i queries/01_basic_queries.sql
```

## Featured Projects

### University Course Management System

A complete database design for managing students, courses, instructors, and enrollments.

**Features:**
- Student and instructor management
- Course catalog and prerequisites
- Enrollment tracking with waitlists
- GPA calculation and academic standing
- Room scheduling and conflict detection

**Key Queries:**
- Find all courses a student can take based on completed prerequisites
- Calculate instructor workload and availability
- Generate academic transcripts
- Identify at-risk students (GPA < 2.0)

### E-commerce Platform

Robust schema for a multi-vendor marketplace.

**Features:**
- Product catalog with categories and variants
- Shopping cart and order processing
- Inventory management
- Customer reviews and ratings
- Payment processing and refunds

**Key Queries:**
- Top-selling products by category
- Customer lifetime value (CLV) calculation
- Cart abandonment analysis
- Inventory forecasting

### Healthcare Patient Records

HIPAA-compliant database for patient management.

**Features:**
- Patient demographics and medical history
- Appointment scheduling
- Prescription tracking
- Lab results and diagnoses
- Insurance and billing

**Key Queries:**
- Patient visit history and frequency
- Medication interaction checks
- Appointment no-show analysis
- Revenue per provider

### Transit System Database

Comprehensive database for public transportation.

**Features:**
- Route and schedule management
- Vehicle fleet tracking
- Real-time delay reporting
- Fare and payment systems
- Ridership analytics

**Key Queries:**
- On-time performance by route
- Peak usage times and patterns
- Revenue analysis by fare type
- Maintenance scheduling optimization

## Sample Queries

### Window Functions - Running Total

```sql
-- Calculate running total of daily revenue
SELECT 
    order_date,
    daily_revenue,
    SUM(daily_revenue) OVER (
        ORDER BY order_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM (
    SELECT 
        DATE(order_timestamp) AS order_date,
        SUM(total_amount) AS daily_revenue
    FROM orders
    GROUP BY DATE(order_timestamp)
) daily_sales
ORDER BY order_date;
```

### CTEs - Customer Segmentation

```sql
-- RFM Analysis (Recency, Frequency, Monetary)
WITH customer_metrics AS (
    SELECT 
        customer_id,
        MAX(order_date) AS last_order_date,
        COUNT(*) AS order_frequency,
        SUM(total_amount) AS total_spent
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT 
        customer_id,
        NTILE(5) OVER (ORDER BY last_order_date DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY order_frequency) AS frequency_score,
        NTILE(5) OVER (ORDER BY total_spent) AS monetary_score
    FROM customer_metrics
)
SELECT 
    customer_id,
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'Promising'
        WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'At Risk'
        ELSE 'Needs Attention'
    END AS customer_segment
FROM rfm_scores;
```

### Recursive CTE - Organization Hierarchy

```sql
-- Find all employees reporting to a manager (directly or indirectly)
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: start with the manager
    SELECT 
        employee_id,
        name,
        manager_id,
        1 AS level,
        name AS path
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: find direct reports
    SELECT 
        e.employee_id,
        e.name,
        e.manager_id,
        eh.level + 1,
        eh.path || ' > ' || e.name
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT 
    employee_id,
    name,
    level,
    path
FROM employee_hierarchy
ORDER BY level, name;
```

## Performance Optimization

### Indexing Strategy

```sql
-- Create composite index for common query patterns
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date DESC);

-- Partial index for active records only
CREATE INDEX idx_active_customers ON customers(customer_id) 
WHERE status = 'active';

-- Index for full-text search
CREATE INDEX idx_product_search ON products 
USING GIN(to_tsvector('english', name || ' ' || description));
```

### Query Optimization Example

```sql
-- BEFORE: Inefficient query with subquery in SELECT
SELECT 
    c.customer_id,
    c.name,
    (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) AS order_count
FROM customers c;

-- AFTER: Optimized with LEFT JOIN
SELECT 
    c.customer_id,
    c.name,
    COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;
```

## Learning Resources

Each SQL file includes:
- Detailed comments explaining the logic
- Multiple solution approaches
- Performance considerations
- Common pitfalls to avoid
- Real-world business context

## Complexity Levels

- **Beginner**: Basic SELECT, WHERE, JOIN
- **Intermediate**: Subqueries, GROUP BY, aggregate functions
- **Advanced**: Window functions, CTEs, query optimization
- **Expert**: Recursive queries, advanced indexing, stored procedures

## Database Coverage

- PostgreSQL (primary)
- MySQL
- SQL Server (T-SQL variants included)
- SQLite (portable examples)

## Business Use Cases

1. **Sales Analytics**: Revenue trends, product performance, sales forecasting
2. **Customer Analytics**: Segmentation, CLV, churn prediction
3. **Operational Metrics**: Inventory turnover, fulfillment times, capacity planning
4. **Financial Reporting**: P&L statements, cost analysis, budget tracking

## Tools & Technologies

- **Database Systems**: PostgreSQL, MySQL, SQL Server
- **ER Diagram Tools**: dbdiagram.io, draw.io
- **Query Tools**: DBeaver, pgAdmin, MySQL Workbench
- **Version Control**: Git for schema versioning

## How to Use This Portfolio

1. **Browse by Topic**: Navigate to relevant folders based on your interest
2. **Run Examples**: Execute queries in your own database environment
3. **Study Comments**: Learn from detailed explanations and best practices
4. **Modify & Experiment**: Adapt queries to your own datasets
5. **Build Upon**: Use schemas as templates for your projects

## Skills Demonstrated

✅ Database design and normalization  
✅ Complex multi-table JOINs  
✅ Window functions and analytics  
✅ Common Table Expressions (CTEs)  
✅ Recursive queries  
✅ Query optimization and indexing  
✅ Stored procedures and functions  
✅ Transaction management  
✅ Data integrity constraints  
✅ Business logic implementation  

## License

This project is licensed under the MIT License.

## Author

**Daniel S. Demoz**
- LinkedIn: [daniel-s-demoz](https://www.linkedin.com/in/daniel-s-demoz)
- Email: brukd.consultant@gmail.com
- GitHub: [@DanielDemoz](https://github.com/DanielDemoz)

## Acknowledgments

- Database design inspired by real-world business scenarios
- Query patterns based on common analytics use cases
- Best practices from PostgreSQL and MySQL documentation

---

*This portfolio demonstrates production-ready SQL skills for data analysis, business intelligence, and database development.*

