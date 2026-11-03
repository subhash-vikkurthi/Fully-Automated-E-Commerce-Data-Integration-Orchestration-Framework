-- Tables
create or replace table ECOMMERCE_PIPELINE.bronze_layer.bronze_orders_data(
order_id varchar(25),
order_date varchar(25),
customer_id varchar(25),
customer_name varchar(25),
age int,
gender varchar(15),
region varchar(15),
city varchar(15),
product_category varchar(20),
product_name varchar(15),
quantity int,
unit_price decimal(10,2),
discount_percentage decimal(5,2),
sales_amount decimal(10,2),
profit decimal(10,2),
shipping_cost decimal(10,2),
payment_method varchar(150),
customer_satisfaction decimal(5,2),
return_flag varchar(10),
order_status varchar(20),
days_to_ship int,
loaded_by varchar(25) default 'SUBHASH_VIKKURTHI',
loaded_time timestamp default current_timestamp()
);



CREATE OR REPLACE TABLE ECOMMERCE_PIPELINE.BRONZE_LAYER.AUDIT_TABLE (
    TABLE_NAME          VARCHAR(200),
    FILE_NAME           VARCHAR(500),
    PROCEDURE_NAME      VARCHAR(200),
    ACTION_TYPE         VARCHAR(100),
    ROWS_READ           NUMBER(38,0),
    ROWS_INSERTED       NUMBER(38,0) DEFAULT 0,
    ROWS_UPDATED        NUMBER(38,0) DEFAULT 0,
    INITIATED_TIME      TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    STATUS              VARCHAR(30),
    START_TIME          TIMESTAMP_NTZ,
    END_TIME            TIMESTAMP_NTZ,
    ERROR_MESSAGE       VARCHAR(2000),
    INITIATED_BY        VARCHAR(200)
);

desc table sales_details.bronze_layer.sales_data;


create or replace table ECOMMERCE_PIPELINE.bronze_layer.bronze_staging
(
order_id varchar(25),
order_date varchar(25),
customer_id varchar(25),
customer_name varchar(25),
age int,
gender varchar(15),
region varchar(15),
city varchar(15),
product_category varchar(20),
product_name varchar(15),
quantity int,
unit_price decimal(10,2),
discount_percentage decimal(5,2),
sales_amount decimal(10,2),
profit decimal(10,2),
shipping_cost decimal(10,2),
payment_method varchar(150),
customer_satisfaction decimal(5,2),
return_flag varchar(10),
order_status varchar(20),
days_to_ship int,
loaded_by varchar(25) default 'SUBHASH_VIKKURTHI',
loaded_time timestamp default current_timestamp(),
METADATA$ACTION varchar(100),
METADATA$ISUPDATE varchar(100),
METADATA$ROW_ID varchar(200)
);

DESC TABLE ECOMMERCE_PIPELINE.bronze_layer.bronze_staging;


create or replace table ECOMMERCE_PIPELINE.silver_layer.silver_stagging
(
order_id varchar(25),
order_date varchar(25),
customer_id varchar(25),
customer_name varchar(25),
age int,
gender varchar(15),
region varchar(15),
city varchar(15),
product_category varchar(20),
product_name varchar(15),
quantity int,
unit_price decimal(10,2),
discount_percentage decimal(5,2),
sales_amount decimal(10,2),
profit decimal(10,2),
shipping_cost decimal(10,2),
payment_method varchar(150),
customer_satisfaction decimal(5,2),
return_flag varchar(10),
order_status varchar(20),
days_to_ship int,
loaded_by varchar(25) default 'SUBHASH_VIKKURTHI',
loaded_on timestamp default current_timestamp(),
new_order_date date,
METADATA$ACTION varchar(100),
METADATA$ISUPDATE varchar(100),
METADATA$ROW_ID varchar(200)
);

DESC TABLE desc table sales_details.bronze_layer.silver_stagging;