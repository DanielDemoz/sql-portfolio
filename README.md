# SQL Portfolio

Collection of database schemas, advanced queries, and business analytics SQL across university, e-commerce, healthcare, and transit domains.

## Problem

Hiring managers and collaborators need proof of production-style SQL—normalization, window functions, CTEs, optimization—not just isolated SELECT examples.

## Approach

Organized schemas and query libraries by complexity: basic joins through recursive CTEs, window functions, stored procedures, and indexing strategies. Included RFM segmentation, cohort analysis, running totals, org hierarchies, and domain-specific analytics for four business scenarios.

## Results

- Four complete schema designs: university, e-commerce, healthcare, transit (TTC-inspired)
- Query tiers from beginner through expert with commented alternatives
- Optimization examples: composite/partial/GIN indexes and subquery-to-JOIN rewrites
- Coverage for PostgreSQL (primary), MySQL, SQL Server, and SQLite variants

## Tech stack

PostgreSQL, MySQL, SQL Server (T-SQL), SQLite; pgAdmin / DBeaver compatible

## How to run

```bash
git clone https://github.com/DanielDemoz/sql-portfolio.git
cd sql-portfolio
psql -U your_username -d your_database
\i schemas/university_system.sql
\i sample_data/generate_sample_data.sql
\i queries/01_basic_queries.sql
```

Browse `schemas/`, `queries/`, `analytics/`, and `procedures/` folders independently.

## Screenshot / demo

**Interactive showcase:** https://danieldemoz.github.io/sql-portfolio/

Each `.sql` file includes inline comments explaining logic, performance notes, and business context.

## Author

**Daniel S. Demoz**

- Email: asbdansi9@gmail.com
- Phone: (437) 249-3308
- LinkedIn: [daniel-s-demoz](https://www.linkedin.com/in/daniel-s-demoz)
- GitHub: [@DanielDemoz](https://github.com/DanielDemoz)
- Website: [brukdconsultancy.com](https://brukdconsultancy.com)
