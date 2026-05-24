DROP TABLE IF EXISTS dw.fact_sales;
DROP TABLE IF EXISTS dw.dim_product;
DROP TABLE IF EXISTS dw.dim_supplier;
DROP TABLE IF EXISTS dw.dim_store;
DROP TABLE IF EXISTS dw.dim_customer;
DROP TABLE IF EXISTS dw.dim_seller;
DROP TABLE IF EXISTS dw.dim_pet;
DROP TABLE IF EXISTS dw.dim_product_attribute;
DROP TABLE IF EXISTS dw.dim_product_category;
DROP TABLE IF EXISTS dw.dim_geo_location;
DROP TABLE IF EXISTS dw.dim_country;
DROP TABLE IF EXISTS dw.dim_date;

CREATE TABLE dw.dim_country (
    country_key bigserial PRIMARY KEY,
    country_name text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_geo_location (
    location_key bigserial PRIMARY KEY,
    country_key bigint REFERENCES dw.dim_country(country_key),
    state_name text,
    city_name text,
    postal_code text,
    address_line text,
    natural_key text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_pet (
    pet_key bigserial PRIMARY KEY,
    pet_type text,
    pet_name text,
    pet_breed text,
    pet_category text,
    natural_key text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_customer (
    customer_key bigserial PRIMARY KEY,
    source_customer_id integer,
    first_name text,
    last_name text,
    age integer,
    email text,
    location_key bigint REFERENCES dw.dim_geo_location(location_key),
    pet_key bigint REFERENCES dw.dim_pet(pet_key),
    natural_key text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_seller (
    seller_key bigserial PRIMARY KEY,
    source_seller_id integer,
    first_name text,
    last_name text,
    email text,
    location_key bigint REFERENCES dw.dim_geo_location(location_key),
    natural_key text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_supplier (
    supplier_key bigserial PRIMARY KEY,
    supplier_name text,
    contact_name text,
    email text,
    phone text,
    location_key bigint REFERENCES dw.dim_geo_location(location_key),
    natural_key text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_store (
    store_key bigserial PRIMARY KEY,
    store_name text,
    phone text,
    email text,
    location_key bigint REFERENCES dw.dim_geo_location(location_key),
    natural_key text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_product_category (
    category_key bigserial PRIMARY KEY,
    category_name text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_product_attribute (
    attribute_key bigserial PRIMARY KEY,
    pet_category text,
    color_name text,
    size_name text,
    brand_name text,
    material_name text,
    natural_key text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_product (
    product_key bigserial PRIMARY KEY,
    source_product_id integer,
    product_name text,
    category_key bigint REFERENCES dw.dim_product_category(category_key),
    attribute_key bigint REFERENCES dw.dim_product_attribute(attribute_key),
    product_description text,
    product_price numeric(12, 2),
    available_quantity integer,
    product_weight numeric(12, 2),
    product_rating numeric(3, 1),
    product_reviews integer,
    release_date date,
    expiry_date date,
    natural_key text NOT NULL UNIQUE
);

CREATE TABLE dw.dim_date (
    date_key integer PRIMARY KEY,
    full_date date NOT NULL UNIQUE,
    day_of_month integer NOT NULL,
    month_number integer NOT NULL,
    quarter_number integer NOT NULL,
    year_number integer NOT NULL,
    day_of_week integer NOT NULL,
    day_name text NOT NULL,
    month_name text NOT NULL
);

CREATE TABLE dw.fact_sales (
    sale_key bigserial PRIMARY KEY,
    source_row_id bigint NOT NULL UNIQUE REFERENCES staging.mock_data(raw_source_id),
    date_key integer NOT NULL REFERENCES dw.dim_date(date_key),
    customer_key bigint NOT NULL REFERENCES dw.dim_customer(customer_key),
    seller_key bigint NOT NULL REFERENCES dw.dim_seller(seller_key),
    product_key bigint NOT NULL REFERENCES dw.dim_product(product_key),
    store_key bigint NOT NULL REFERENCES dw.dim_store(store_key),
    supplier_key bigint NOT NULL REFERENCES dw.dim_supplier(supplier_key),
    source_sale_customer_id integer,
    source_sale_seller_id integer,
    source_sale_product_id integer,
    sale_quantity integer NOT NULL,
    sale_total_price numeric(12, 2) NOT NULL,
    product_unit_price numeric(12, 2),
    loaded_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_fact_sales_date_key ON dw.fact_sales(date_key);
CREATE INDEX idx_fact_sales_customer_key ON dw.fact_sales(customer_key);
CREATE INDEX idx_fact_sales_product_key ON dw.fact_sales(product_key);
CREATE INDEX idx_fact_sales_store_key ON dw.fact_sales(store_key);

