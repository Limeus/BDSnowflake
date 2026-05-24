TRUNCATE TABLE
    dw.fact_sales,
    dw.dim_product,
    dw.dim_supplier,
    dw.dim_store,
    dw.dim_customer,
    dw.dim_seller,
    dw.dim_pet,
    dw.dim_product_attribute,
    dw.dim_product_category,
    dw.dim_geo_location,
    dw.dim_country,
    dw.dim_date
RESTART IDENTITY CASCADE;

INSERT INTO dw.dim_country (country_name)
SELECT DISTINCT country_name
FROM (
    SELECT NULLIF(BTRIM(customer_country), '') AS country_name FROM staging.mock_data
    UNION
    SELECT NULLIF(BTRIM(seller_country), '') FROM staging.mock_data
    UNION
    SELECT NULLIF(BTRIM(store_country), '') FROM staging.mock_data
    UNION
    SELECT NULLIF(BTRIM(supplier_country), '') FROM staging.mock_data
) countries
WHERE country_name IS NOT NULL
ORDER BY country_name;

INSERT INTO dw.dim_geo_location (
    country_key,
    state_name,
    city_name,
    postal_code,
    address_line,
    natural_key
)
SELECT
    c.country_key,
    g.state_name,
    g.city_name,
    g.postal_code,
    g.address_line,
    md5(concat_ws('|',
        COALESCE(g.country_name, ''),
        COALESCE(g.state_name, ''),
        COALESCE(g.city_name, ''),
        COALESCE(g.postal_code, ''),
        COALESCE(g.address_line, '')
    )) AS natural_key
FROM (
    SELECT DISTINCT
        NULLIF(BTRIM(customer_country), '') AS country_name,
        NULL::text AS state_name,
        NULL::text AS city_name,
        NULLIF(BTRIM(customer_postal_code), '') AS postal_code,
        NULL::text AS address_line
    FROM staging.mock_data
    UNION
    SELECT DISTINCT
        NULLIF(BTRIM(seller_country), ''),
        NULL::text,
        NULL::text,
        NULLIF(BTRIM(seller_postal_code), ''),
        NULL::text
    FROM staging.mock_data
    UNION
    SELECT DISTINCT
        NULLIF(BTRIM(store_country), ''),
        NULLIF(BTRIM(store_state), ''),
        NULLIF(BTRIM(store_city), ''),
        NULL::text,
        NULLIF(BTRIM(store_location), '')
    FROM staging.mock_data
    UNION
    SELECT DISTINCT
        NULLIF(BTRIM(supplier_country), ''),
        NULL::text,
        NULLIF(BTRIM(supplier_city), ''),
        NULL::text,
        NULLIF(BTRIM(supplier_address), '')
    FROM staging.mock_data
) g
LEFT JOIN dw.dim_country c ON c.country_name = g.country_name
WHERE g.country_name IS NOT NULL
   OR g.state_name IS NOT NULL
   OR g.city_name IS NOT NULL
   OR g.postal_code IS NOT NULL
   OR g.address_line IS NOT NULL
ORDER BY g.country_name, g.state_name, g.city_name, g.postal_code, g.address_line;

INSERT INTO dw.dim_pet (pet_type, pet_name, pet_breed, pet_category, natural_key)
SELECT DISTINCT
    NULLIF(BTRIM(customer_pet_type), '') AS pet_type,
    NULLIF(BTRIM(customer_pet_name), '') AS pet_name,
    NULLIF(BTRIM(customer_pet_breed), '') AS pet_breed,
    NULLIF(BTRIM(pet_category), '') AS pet_category,
    md5(concat_ws('|',
        COALESCE(NULLIF(BTRIM(customer_pet_type), ''), ''),
        COALESCE(NULLIF(BTRIM(customer_pet_name), ''), ''),
        COALESCE(NULLIF(BTRIM(customer_pet_breed), ''), ''),
        COALESCE(NULLIF(BTRIM(pet_category), ''), '')
    )) AS natural_key
FROM staging.mock_data;

INSERT INTO dw.dim_customer (
    source_customer_id,
    first_name,
    last_name,
    age,
    email,
    location_key,
    pet_key,
    natural_key
)
SELECT DISTINCT
    m.sale_customer_id,
    NULLIF(BTRIM(m.customer_first_name), ''),
    NULLIF(BTRIM(m.customer_last_name), ''),
    m.customer_age,
    NULLIF(BTRIM(m.customer_email), ''),
    gl.location_key,
    p.pet_key,
    md5(concat_ws('|',
        COALESCE(m.sale_customer_id::text, ''),
        COALESCE(NULLIF(BTRIM(m.customer_first_name), ''), ''),
        COALESCE(NULLIF(BTRIM(m.customer_last_name), ''), ''),
        COALESCE(m.customer_age::text, ''),
        COALESCE(NULLIF(BTRIM(m.customer_email), ''), ''),
        COALESCE(gl.natural_key, ''),
        COALESCE(p.natural_key, '')
    )) AS natural_key
FROM staging.mock_data m
JOIN dw.dim_geo_location gl
  ON gl.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.customer_country), ''), ''),
      '',
      '',
      COALESCE(NULLIF(BTRIM(m.customer_postal_code), ''), ''),
      ''
  ))
JOIN dw.dim_pet p
  ON p.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.customer_pet_type), ''), ''),
      COALESCE(NULLIF(BTRIM(m.customer_pet_name), ''), ''),
      COALESCE(NULLIF(BTRIM(m.customer_pet_breed), ''), ''),
      COALESCE(NULLIF(BTRIM(m.pet_category), ''), '')
  ));

INSERT INTO dw.dim_seller (
    source_seller_id,
    first_name,
    last_name,
    email,
    location_key,
    natural_key
)
SELECT DISTINCT
    m.sale_seller_id,
    NULLIF(BTRIM(m.seller_first_name), ''),
    NULLIF(BTRIM(m.seller_last_name), ''),
    NULLIF(BTRIM(m.seller_email), ''),
    gl.location_key,
    md5(concat_ws('|',
        COALESCE(m.sale_seller_id::text, ''),
        COALESCE(NULLIF(BTRIM(m.seller_first_name), ''), ''),
        COALESCE(NULLIF(BTRIM(m.seller_last_name), ''), ''),
        COALESCE(NULLIF(BTRIM(m.seller_email), ''), ''),
        COALESCE(gl.natural_key, '')
    )) AS natural_key
FROM staging.mock_data m
JOIN dw.dim_geo_location gl
  ON gl.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.seller_country), ''), ''),
      '',
      '',
      COALESCE(NULLIF(BTRIM(m.seller_postal_code), ''), ''),
      ''
  ));

INSERT INTO dw.dim_supplier (
    supplier_name,
    contact_name,
    email,
    phone,
    location_key,
    natural_key
)
SELECT DISTINCT
    NULLIF(BTRIM(m.supplier_name), ''),
    NULLIF(BTRIM(m.supplier_contact), ''),
    NULLIF(BTRIM(m.supplier_email), ''),
    NULLIF(BTRIM(m.supplier_phone), ''),
    gl.location_key,
    md5(concat_ws('|',
        COALESCE(NULLIF(BTRIM(m.supplier_name), ''), ''),
        COALESCE(NULLIF(BTRIM(m.supplier_contact), ''), ''),
        COALESCE(NULLIF(BTRIM(m.supplier_email), ''), ''),
        COALESCE(NULLIF(BTRIM(m.supplier_phone), ''), ''),
        COALESCE(gl.natural_key, '')
    )) AS natural_key
FROM staging.mock_data m
JOIN dw.dim_geo_location gl
  ON gl.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.supplier_country), ''), ''),
      '',
      COALESCE(NULLIF(BTRIM(m.supplier_city), ''), ''),
      '',
      COALESCE(NULLIF(BTRIM(m.supplier_address), ''), '')
  ));

INSERT INTO dw.dim_store (
    store_name,
    phone,
    email,
    location_key,
    natural_key
)
SELECT DISTINCT
    NULLIF(BTRIM(m.store_name), ''),
    NULLIF(BTRIM(m.store_phone), ''),
    NULLIF(BTRIM(m.store_email), ''),
    gl.location_key,
    md5(concat_ws('|',
        COALESCE(NULLIF(BTRIM(m.store_name), ''), ''),
        COALESCE(NULLIF(BTRIM(m.store_phone), ''), ''),
        COALESCE(NULLIF(BTRIM(m.store_email), ''), ''),
        COALESCE(gl.natural_key, '')
    )) AS natural_key
FROM staging.mock_data m
JOIN dw.dim_geo_location gl
  ON gl.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.store_country), ''), ''),
      COALESCE(NULLIF(BTRIM(m.store_state), ''), ''),
      COALESCE(NULLIF(BTRIM(m.store_city), ''), ''),
      '',
      COALESCE(NULLIF(BTRIM(m.store_location), ''), '')
  ));

INSERT INTO dw.dim_product_category (category_name)
SELECT DISTINCT NULLIF(BTRIM(product_category), '') AS category_name
FROM staging.mock_data
WHERE NULLIF(BTRIM(product_category), '') IS NOT NULL
ORDER BY category_name;

INSERT INTO dw.dim_product_attribute (
    pet_category,
    color_name,
    size_name,
    brand_name,
    material_name,
    natural_key
)
SELECT DISTINCT
    NULLIF(BTRIM(pet_category), ''),
    NULLIF(BTRIM(product_color), ''),
    NULLIF(BTRIM(product_size), ''),
    NULLIF(BTRIM(product_brand), ''),
    NULLIF(BTRIM(product_material), ''),
    md5(concat_ws('|',
        COALESCE(NULLIF(BTRIM(pet_category), ''), ''),
        COALESCE(NULLIF(BTRIM(product_color), ''), ''),
        COALESCE(NULLIF(BTRIM(product_size), ''), ''),
        COALESCE(NULLIF(BTRIM(product_brand), ''), ''),
        COALESCE(NULLIF(BTRIM(product_material), ''), '')
    )) AS natural_key
FROM staging.mock_data;

INSERT INTO dw.dim_product (
    source_product_id,
    product_name,
    category_key,
    attribute_key,
    product_description,
    product_price,
    available_quantity,
    product_weight,
    product_rating,
    product_reviews,
    release_date,
    expiry_date,
    natural_key
)
SELECT DISTINCT
    m.sale_product_id,
    NULLIF(BTRIM(m.product_name), ''),
    pc.category_key,
    pa.attribute_key,
    NULLIF(BTRIM(m.product_description), ''),
    m.product_price,
    m.product_quantity,
    m.product_weight,
    m.product_rating,
    m.product_reviews,
    to_date(m.product_release_date, 'MM/DD/YYYY'),
    to_date(m.product_expiry_date, 'MM/DD/YYYY'),
    md5(concat_ws('|',
        COALESCE(m.sale_product_id::text, ''),
        COALESCE(NULLIF(BTRIM(m.product_name), ''), ''),
        COALESCE(pc.category_key::text, ''),
        COALESCE(pa.attribute_key::text, ''),
        COALESCE(NULLIF(BTRIM(m.product_description), ''), ''),
        COALESCE(m.product_price::text, ''),
        COALESCE(m.product_quantity::text, ''),
        COALESCE(m.product_weight::text, ''),
        COALESCE(m.product_rating::text, ''),
        COALESCE(m.product_reviews::text, ''),
        COALESCE(m.product_release_date, ''),
        COALESCE(m.product_expiry_date, '')
    )) AS natural_key
FROM staging.mock_data m
JOIN dw.dim_product_category pc
  ON pc.category_name = NULLIF(BTRIM(m.product_category), '')
JOIN dw.dim_product_attribute pa
  ON pa.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.pet_category), ''), ''),
      COALESCE(NULLIF(BTRIM(m.product_color), ''), ''),
      COALESCE(NULLIF(BTRIM(m.product_size), ''), ''),
      COALESCE(NULLIF(BTRIM(m.product_brand), ''), ''),
      COALESCE(NULLIF(BTRIM(m.product_material), ''), '')
  ));

INSERT INTO dw.dim_date (
    date_key,
    full_date,
    day_of_month,
    month_number,
    quarter_number,
    year_number,
    day_of_week,
    day_name,
    month_name
)
SELECT DISTINCT
    to_char(to_date(sale_date, 'MM/DD/YYYY'), 'YYYYMMDD')::integer AS date_key,
    to_date(sale_date, 'MM/DD/YYYY') AS full_date,
    EXTRACT(day FROM to_date(sale_date, 'MM/DD/YYYY'))::integer AS day_of_month,
    EXTRACT(month FROM to_date(sale_date, 'MM/DD/YYYY'))::integer AS month_number,
    EXTRACT(quarter FROM to_date(sale_date, 'MM/DD/YYYY'))::integer AS quarter_number,
    EXTRACT(year FROM to_date(sale_date, 'MM/DD/YYYY'))::integer AS year_number,
    EXTRACT(isodow FROM to_date(sale_date, 'MM/DD/YYYY'))::integer AS day_of_week,
    TRIM(to_char(to_date(sale_date, 'MM/DD/YYYY'), 'Day')) AS day_name,
    TRIM(to_char(to_date(sale_date, 'MM/DD/YYYY'), 'Month')) AS month_name
FROM staging.mock_data
WHERE NULLIF(BTRIM(sale_date), '') IS NOT NULL;

INSERT INTO dw.fact_sales (
    source_row_id,
    date_key,
    customer_key,
    seller_key,
    product_key,
    store_key,
    supplier_key,
    source_sale_customer_id,
    source_sale_seller_id,
    source_sale_product_id,
    sale_quantity,
    sale_total_price,
    product_unit_price
)
SELECT
    m.raw_source_id,
    d.date_key,
    c.customer_key,
    s.seller_key,
    p.product_key,
    st.store_key,
    sup.supplier_key,
    m.sale_customer_id,
    m.sale_seller_id,
    m.sale_product_id,
    m.sale_quantity,
    m.sale_total_price,
    m.product_price
FROM staging.mock_data m
JOIN dw.dim_date d
  ON d.full_date = to_date(m.sale_date, 'MM/DD/YYYY')
JOIN dw.dim_geo_location customer_gl
  ON customer_gl.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.customer_country), ''), ''),
      '',
      '',
      COALESCE(NULLIF(BTRIM(m.customer_postal_code), ''), ''),
      ''
  ))
JOIN dw.dim_pet pet
  ON pet.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.customer_pet_type), ''), ''),
      COALESCE(NULLIF(BTRIM(m.customer_pet_name), ''), ''),
      COALESCE(NULLIF(BTRIM(m.customer_pet_breed), ''), ''),
      COALESCE(NULLIF(BTRIM(m.pet_category), ''), '')
  ))
JOIN dw.dim_customer c
  ON c.natural_key = md5(concat_ws('|',
      COALESCE(m.sale_customer_id::text, ''),
      COALESCE(NULLIF(BTRIM(m.customer_first_name), ''), ''),
      COALESCE(NULLIF(BTRIM(m.customer_last_name), ''), ''),
      COALESCE(m.customer_age::text, ''),
      COALESCE(NULLIF(BTRIM(m.customer_email), ''), ''),
      COALESCE(customer_gl.natural_key, ''),
      COALESCE(pet.natural_key, '')
  ))
JOIN dw.dim_geo_location seller_gl
  ON seller_gl.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.seller_country), ''), ''),
      '',
      '',
      COALESCE(NULLIF(BTRIM(m.seller_postal_code), ''), ''),
      ''
  ))
JOIN dw.dim_seller s
  ON s.natural_key = md5(concat_ws('|',
      COALESCE(m.sale_seller_id::text, ''),
      COALESCE(NULLIF(BTRIM(m.seller_first_name), ''), ''),
      COALESCE(NULLIF(BTRIM(m.seller_last_name), ''), ''),
      COALESCE(NULLIF(BTRIM(m.seller_email), ''), ''),
      COALESCE(seller_gl.natural_key, '')
  ))
JOIN dw.dim_product_category pc
  ON pc.category_name = NULLIF(BTRIM(m.product_category), '')
JOIN dw.dim_product_attribute pa
  ON pa.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.pet_category), ''), ''),
      COALESCE(NULLIF(BTRIM(m.product_color), ''), ''),
      COALESCE(NULLIF(BTRIM(m.product_size), ''), ''),
      COALESCE(NULLIF(BTRIM(m.product_brand), ''), ''),
      COALESCE(NULLIF(BTRIM(m.product_material), ''), '')
  ))
JOIN dw.dim_product p
  ON p.natural_key = md5(concat_ws('|',
      COALESCE(m.sale_product_id::text, ''),
      COALESCE(NULLIF(BTRIM(m.product_name), ''), ''),
      COALESCE(pc.category_key::text, ''),
      COALESCE(pa.attribute_key::text, ''),
      COALESCE(NULLIF(BTRIM(m.product_description), ''), ''),
      COALESCE(m.product_price::text, ''),
      COALESCE(m.product_quantity::text, ''),
      COALESCE(m.product_weight::text, ''),
      COALESCE(m.product_rating::text, ''),
      COALESCE(m.product_reviews::text, ''),
      COALESCE(m.product_release_date, ''),
      COALESCE(m.product_expiry_date, '')
  ))
JOIN dw.dim_geo_location store_gl
  ON store_gl.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.store_country), ''), ''),
      COALESCE(NULLIF(BTRIM(m.store_state), ''), ''),
      COALESCE(NULLIF(BTRIM(m.store_city), ''), ''),
      '',
      COALESCE(NULLIF(BTRIM(m.store_location), ''), '')
  ))
JOIN dw.dim_store st
  ON st.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.store_name), ''), ''),
      COALESCE(NULLIF(BTRIM(m.store_phone), ''), ''),
      COALESCE(NULLIF(BTRIM(m.store_email), ''), ''),
      COALESCE(store_gl.natural_key, '')
  ))
JOIN dw.dim_geo_location supplier_gl
  ON supplier_gl.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.supplier_country), ''), ''),
      '',
      COALESCE(NULLIF(BTRIM(m.supplier_city), ''), ''),
      '',
      COALESCE(NULLIF(BTRIM(m.supplier_address), ''), '')
  ))
JOIN dw.dim_supplier sup
  ON sup.natural_key = md5(concat_ws('|',
      COALESCE(NULLIF(BTRIM(m.supplier_name), ''), ''),
      COALESCE(NULLIF(BTRIM(m.supplier_contact), ''), ''),
      COALESCE(NULLIF(BTRIM(m.supplier_email), ''), ''),
      COALESCE(NULLIF(BTRIM(m.supplier_phone), ''), ''),
      COALESCE(supplier_gl.natural_key, '')
  ));
