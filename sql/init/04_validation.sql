CREATE OR REPLACE VIEW dw.v_lab1_validation AS
SELECT 'staging.mock_data' AS object_name, COUNT(*) AS row_count FROM staging.mock_data
UNION ALL SELECT 'dw.dim_country', COUNT(*) FROM dw.dim_country
UNION ALL SELECT 'dw.dim_geo_location', COUNT(*) FROM dw.dim_geo_location
UNION ALL SELECT 'dw.dim_pet', COUNT(*) FROM dw.dim_pet
UNION ALL SELECT 'dw.dim_customer', COUNT(*) FROM dw.dim_customer
UNION ALL SELECT 'dw.dim_seller', COUNT(*) FROM dw.dim_seller
UNION ALL SELECT 'dw.dim_supplier', COUNT(*) FROM dw.dim_supplier
UNION ALL SELECT 'dw.dim_store', COUNT(*) FROM dw.dim_store
UNION ALL SELECT 'dw.dim_product_category', COUNT(*) FROM dw.dim_product_category
UNION ALL SELECT 'dw.dim_product_attribute', COUNT(*) FROM dw.dim_product_attribute
UNION ALL SELECT 'dw.dim_product', COUNT(*) FROM dw.dim_product
UNION ALL SELECT 'dw.dim_date', COUNT(*) FROM dw.dim_date
UNION ALL SELECT 'dw.fact_sales', COUNT(*) FROM dw.fact_sales;

CREATE OR REPLACE VIEW dw.v_sales_by_country AS
SELECT
    country.country_name,
    COUNT(*) AS sales_count,
    SUM(f.sale_quantity) AS total_quantity,
    SUM(f.sale_total_price) AS total_sales_amount
FROM dw.fact_sales f
JOIN dw.dim_customer customer ON customer.customer_key = f.customer_key
JOIN dw.dim_geo_location location ON location.location_key = customer.location_key
JOIN dw.dim_country country ON country.country_key = location.country_key
GROUP BY country.country_name;

CREATE OR REPLACE VIEW dw.v_sales_by_product_category AS
SELECT
    category.category_name,
    COUNT(*) AS sales_count,
    SUM(f.sale_quantity) AS total_quantity,
    SUM(f.sale_total_price) AS total_sales_amount
FROM dw.fact_sales f
JOIN dw.dim_product product ON product.product_key = f.product_key
JOIN dw.dim_product_category category ON category.category_key = product.category_key
GROUP BY category.category_name;

