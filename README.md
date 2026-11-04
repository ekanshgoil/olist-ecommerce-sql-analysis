# Olist E-Commerce Sales Analysis | SQL (PostgreSQL)

Analysis of ~100K orders from Olist, a Brazilian online marketplace (2016–2018), using SQL to answer basic questions about sales, products, customers, payments and delivery.

**Dataset:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle). Amounts are in Brazilian Real (R$).
**Tables:** `orders`, `order_items`, `customers`, `products`, `order_payments`
**Tools:** PostgreSQL, pgAdmin

## Files
| File | Purpose |
|---|---|
| `Olist_Ecommerce.sql` | One script with 3 parts: create tables, basic data checks, and 10 business queries |

## SQL concepts used
SELECT, WHERE, JOINs (up to 3 tables), GROUP BY, HAVING, ORDER BY, LIMIT, aggregate functions (COUNT, SUM, AVG), CASE WHEN, subqueries

## Data checks
- 2,965 orders have no delivery date (cancelled or in transit), so sales analysis uses only `delivered` orders.
- `customer_id` is new for every order; `customer_unique_id` identifies the real customer (96,096 people vs 99,441 ids).
- 610 products have no category.

## Key findings
- **Sales:** 96,478 delivered orders, R$13.2M revenue, average order value R$137.
- **Trend:** Monthly revenue grew from about R$112K (Jan 2017) to about R$978K (May 2018), with a peak in November 2017 (R$988K).
- **Products:** `beleza_saude`, `relogios_presentes` and `cama_mesa_banho` are the top 3 categories by revenue.
- **Location:** São Paulo (SP) brings about 38% of revenue, far ahead of RJ and MG.
- **Payments:** Credit card is the most used method, with an average of 3.5 instalments.
- **Delivery:** Average delivery takes 12.5 days and 8.1% of orders arrive late. Amazonas (AM) is slowest at 26.4 days.
- **Customers:** Only about 3% of customers (2,801) ordered more than once, so repeat purchases are a clear opportunity.

## How to run
1. Create a database named `olist_ecommerce` in pgAdmin.
2. Open `Olist_Ecommerce.sql` in the Query Tool and run only the **Create Tables** part. Warning: the `DROP TABLE` line deletes all data, so never run it after loading.
3. Import the 5 CSV files with pgAdmin's Import/Export wizard (order: customers, products, orders, order_items, order_payments).
4. Run the data checks and the queries one by one (select a query and press F5).

