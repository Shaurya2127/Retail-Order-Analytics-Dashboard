-- View 1: Customer Demographics with Region Sales Target
CREATE VIEW vw_customer_demographics AS
SELECT
    c.customer_id,
    c.gender,
    c.age,
    c.region AS customer_region,
    r.region_name,
    r.sales_target,
    c.sign_up_date
FROM customers c
JOIN regions r ON c.region = r.region_name;

-- View 2: Regional Sales Performance Summary
CREATE VIEW vw_region_sales_summary AS
SELECT
    r.region_name,
    r.sales_target,
    SUM(oi.quantity * oi.price) AS total_sales,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN regions r ON c.region = r.region_name
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY r.region_name, r.sales_target;

-- View 3: Monthly Sales Trend
CREATE VIEW vw_monthly_sales_trend AS
SELECT
    FORMAT(o.order_date, 'yyyy-MM') AS order_month,
    SUM(oi.quantity * oi.price) AS monthly_sales,
    COUNT(DISTINCT o.order_id) AS order_count
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY FORMAT(o.order_date, 'yyyy-MM');

-- View 4: Top Products by Sales
CREATE VIEW vw_top_products_sales AS
SELECT
    p.product_name,
    SUM(oi.quantity * oi.price) AS total_sales,
    SUM(oi.quantity) AS total_quantity
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name;

CREATE VIEW vw_customer_purchase_summary AS
SELECT
    c.customer_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * oi.price) AS total_spent,
    AVG(oi.quantity * oi.price) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id;

CREATE VIEW vw_product_sales_by_region AS
SELECT
    r.region_name,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.quantity * oi.price) AS total_revenue
FROM regions r
JOIN customers c ON c.region = r.region_name
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY r.region_name, p.product_name;

CREATE PROCEDURE sp_top_customers_by_region
    @RegionName NVARCHAR(100)
AS
BEGIN
    SELECT TOP 5
        c.customer_id,
        c.gender,
        c.age,
        SUM(oi.quantity * oi.price) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE c.region = @RegionName
    GROUP BY c.customer_id, c.gender, c.age
    ORDER BY total_spent DESC;
END;

EXEC sp_top_customers_by_region @RegionName = 'North';

CREATE PROCEDURE sp_monthly_sales_summary
    @Year INT
AS
BEGIN
    SELECT
        FORMAT(o.order_date, 'yyyy-MM') AS month,
        SUM(oi.quantity * oi.price) AS total_sales,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE YEAR(o.order_date) = @Year
    GROUP BY FORMAT(o.order_date, 'yyyy-MM')
    ORDER BY month;
END;

EXEC sp_monthly_sales_summary @Year = 2024;

-- Index for JOIN and filtering on customer_id
CREATE NONCLUSTERED INDEX idx_orders_customer_id ON orders(customer_id);

-- Index for fast time-based filtering
CREATE NONCLUSTERED INDEX idx_orders_order_date ON orders(order_date);

-- Index on region (frequently joined and filtered)
CREATE NONCLUSTERED INDEX idx_customers_region ON customers(region);

-- Index on product_id
CREATE NONCLUSTERED INDEX idx_order_items_product_id ON order_items(product_id);

CREATE VIEW vw_monthly_sales_by_regions AS
SELECT
    FORMAT(o.order_date, 'yyyy-MM') AS order_month,
    c.region AS region_name,
    SUM(oi.quantity * oi.price) AS monthly_sales
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY FORMAT(o.order_date, 'yyyy-MM'), c.region;

CREATE VIEW vw_monthly_sales_by_products AS
SELECT
    FORMAT(o.order_date, 'yyyy-MM') AS order_month,
    p.product_name,
    SUM(oi.quantity * oi.price) AS monthly_sales
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY FORMAT(o.order_date, 'yyyy-MM'), p.product_name;
