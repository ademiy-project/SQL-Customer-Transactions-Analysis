# SQL: Customer & Transactions Analysis

Analysis of customer and transaction data for the period 01.06.2015 – 01.06.2016.

## Data
Source files provided with the assignment (not included in this repository, all data is already loaded into `FP_DB.sql`):
- `customer_info.xlsx`: customer information
- `transactions_info.xlsx`: transaction records

## Database
`FP_DB.sql` is a MySQL 8.0 dump that creates the database **`finalproject`** with two tables:

**`customers`** (2,429 rows)
| Column | Type | Description |
|---|---|---|
| `Id_client` | int | Client ID |
| `Total_amount` | int | Total purchase amount |
| `Gender` | text | M / F / empty (treated as NA) |
| `Age` | int | Client age (NULL if unknown) |
| `Count_city` | int | Number of cities |
| `Response_communcation` | int | Responded to communication (0/1) |
| `Communication_3month` | int | Communication in the last 3 months (0/1) |
| `Tenure` | int | Client tenure |

**`transactions`** (419,122 rows)
| Column | Type | Description |
|---|---|---|
| `date_new` | date | Transaction month |
| `Id_check` | int | Receipt (check) ID |
| `ID_client` | int | Client ID (links to `customers.Id_client`) |
| `Count_products` | decimal(10,3) | Number of products |
| `Sum_payment` | decimal(10,2) | Payment amount |

## Tasks
1. Clients with a continuous 12-month history (a transaction in every month), with average check, average monthly purchase amount, and total number of operations
2. Monthly breakdown:
   - 2.1 average check per month
   - 2.2 average number of operations per month
   - 2.3 average number of active clients
   - 2.4 share of total yearly operations and share of total amount per month
   - 2.5 M/F/NA ratio per month with their share of spending
3. Age groups (10-year bins + NA):
   - 3.1 total amount and number of operations for the whole period
   - 3.2 quarterly averages and percentages

## Tools
SQL (MySQL 8.0): CTEs, window functions, CASE, date functions

## Files
- `FP_DB.sql`: database dump (structure + data)
- `FINAL_PROJECT_Customers_Transactions.sql`: all SQL queries with comments. It contains two versions:
  - **12 months** (June 2015 – May 2016, end date not included)
  - **13 months** (June 2015 – June 2016, end date included)

## How to Run
1. Import `FP_DB.sql` in MySQL Workbench (Server → Data Import) or run:
   `mysql -u root -p < FP_DB.sql`
2. Open `FINAL_PROJECT_Customers_Transactions.sql` and run the queries (the file starts with `USE finalproject;`).
3. Optional: uncomment the `CREATE INDEX` lines at the top to make the JOINs faster.
