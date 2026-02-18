SELECT 
    'customers' as table_name,
    COUNT(*) as row_count
FROM dbo.olist_customers_dataset
UNION ALL
SELECT 'geolocation', COUNT(*) FROM dbo.olist_geolocation_dataset
UNION ALL
SELECT 'order_items', COUNT(*) FROM dbo.olist_order_items_dataset
UNION ALL
SELECT 'order_payments', COUNT(*) FROM dbo.olist_order_payments_dataset
UNION ALL
SELECT 'orders', COUNT(*) FROM dbo.olist_orders_dataset
UNION ALL
SELECT 'products', COUNT(*) FROM dbo.olist_products_dataset
UNION ALL
SELECT 'sellers', COUNT(*) FROM dbo.olist_sellers_dataset
UNION ALL
SELECT 'product_category_name_translation', COUNT(*) FROM dbo.product_category_name_translation;


SELECT TOP 5 * FROM dbo.olist_orders_dataset;

-- 2. orders 테이블 컬럼 상세 정보
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH as max_len,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'olist_orders_dataset'
ORDER BY ORDINAL_POSITION;

-- 3. customers 테이블 컬럼 확인
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'olist_customers_dataset'
ORDER BY ORDINAL_POSITION;

--1 기본 테이블 정보
SELECT 
    'orders' as table_name,
    COUNT(*) as row_count,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'olist_orders_dataset') as column_count
FROM dbo.olist_orders_dataset;


-- 주문 상태 확인
SELECT 
    order_status,
    COUNT(*) as count,
    FORMAT(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 'N2') + '%' as percentage
FROM dbo.olist_orders_dataset
GROUP BY order_status
ORDER BY count DESC;


--날짜 범위 확인
SELECT 
    MIN(order_purchase_timestamp) as first_order,
    MAX(order_purchase_timestamp) as last_order,
    DATEDIFF(month, MIN(order_purchase_timestamp), MAX(order_purchase_timestamp)) as months_span
FROM dbo.olist_orders_dataset;


--월별 주문 트렌드 분석
SELECT 
    FORMAT(order_purchase_timestamp, 'yyyy-MM') as year_month,
    COUNT(*) as order_count,
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) as delivered_orders,
    SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END) as canceled_orders
FROM dbo.olist_orders_dataset
GROUP BY FORMAT(order_purchase_timestamp, 'yyyy-MM')
ORDER BY year_month;


-- 결제 데이터와 연결하기
SELECT TOP 10
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    p.payment_type,
    p.payment_value,
    p.payment_installments
FROM dbo.olist_orders_dataset o
INNER JOIN dbo.olist_order_payments_dataset p 
    ON o.order_id = p.order_id
ORDER BY o.order_purchase_timestamp DESC;


-- 기본 매출 통계
SELECT 
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT o.customer_id) as total_customers,
    SUM(p.payment_value) as total_revenue,
    AVG(p.payment_value) as avg_order_value
FROM dbo.olist_orders_dataset o
JOIN dbo.olist_order_payments_dataset p 
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';


--월별 매출 + 성장률 분석
SELECT 
    FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS month,
    SUM(p.payment_value) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders,
    AVG(p.payment_value) AS avg_order_value
FROM dbo.olist_orders_dataset o
JOIN dbo.olist_order_payments_dataset p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
ORDER BY month;



--지역별 매출 분석
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(p.payment_value) AS revenue
FROM dbo.olist_orders_dataset o
JOIN dbo.olist_customers_dataset c
    ON o.customer_id = c.customer_id
JOIN dbo.olist_order_payments_dataset p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC;

EXEC sp_rename 
    'product_category_name_translation.column1',
    'product_category_name',
    'COLUMN';

EXEC sp_rename 
    'product_category_name_translation.column2',
    'product_category_name_english',
    'COLUMN';


--상품 카테고리 매출 분석

SELECT 
    t.product_category_name_english,
    SUM(oi.price) AS product_sales
FROM dbo.olist_order_items_dataset oi
JOIN dbo.olist_products_dataset pr
    ON oi.product_id = pr.product_id
JOIN dbo.product_category_name_translation t
    ON pr.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY product_sales DESC;


--배송 성능 분석
SELECT 
    AVG(DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) AS avg_delivery_days
FROM dbo.olist_orders_dataset
WHERE order_status = 'delivered';





DROP VIEW IF EXISTS dbo.sales_master;

GO
CREATE VIEW dbo.sales_master AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,

    c.customer_state,
    c.customer_city,

    p.payment_value,
    p.payment_type,

    oi.price,
    oi.freight_value,

    t.product_category_name_english

FROM dbo.olist_orders_dataset o

JOIN dbo.olist_customers_dataset c
    ON o.customer_id = c.customer_id

JOIN dbo.olist_order_payments_dataset p
    ON o.order_id = p.order_id

JOIN dbo.olist_order_items_dataset oi
    ON o.order_id = oi.order_id

JOIN dbo.olist_products_dataset pr
    ON oi.product_id = pr.product_id

LEFT JOIN dbo.product_category_name_translation t
    ON pr.product_category_name = t.product_category_name

WHERE o.order_status = 'delivered';
GO

--view test
SELECT TOP 10 * 
FROM dbo.sales_master;

