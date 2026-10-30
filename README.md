# SQL Portfolio

PostgreSQL patterns that are tested, not just written.

**Page:** https://danieldemoz.github.io/sql-portfolio/

## What is here

| File | What it shows |
|---|---|
| `schemas/university_system.sql` | 8-table university schema with constraints, indexes and views |
| `queries/03_window_functions.sql` | 9 window-function examples on that schema: ranking, top-N per group, running totals, LAG/LEAD, FIRST_VALUE/LAST_VALUE, percentiles, moving averages, gaps and islands |
| `analytics/customer_analytics.sql` | RFM scoring, CLV, cohort retention and churn indicators for a generic e-commerce schema (customers, orders, order_items) that is not included |

## Testing

GitHub Actions loads the schema into PostgreSQL 16 and runs every window-function example on each push. One example used `PERCENTILE_CONT ... OVER ()`, which PostgreSQL does not allow, and was rewritten with a CTE. There is no sample data, so the tests check that the SQL runs, not its results.

## How to run

```bash
createdb university
psql -d university -f schemas/university_system.sql
psql -d university -f queries/03_window_functions.sql
```

For `analytics/customer_analytics.sql`, adapt the table names to your own e-commerce schema first.

## Responsible use

Student and customer records are personal information. Real use needs access controls, and queries should select only the columns an analysis needs.

## Project history

The earlier README listed four schemas (university, e-commerce, healthcare, transit), stored procedures and sample data. Only the three files above are in the repository, so the README was corrected in October 2026.

## Author

Daniel S. Demoz · [danieldemoz.com](https://www.danieldemoz.com) · [LinkedIn](https://www.linkedin.com/in/daniel-s-demoz) · [GitHub](https://github.com/DanielDemoz)
