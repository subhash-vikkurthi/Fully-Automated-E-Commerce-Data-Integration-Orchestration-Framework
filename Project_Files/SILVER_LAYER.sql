create schema silver_layer;

create or replace table ECOMMERCE_PIPELINE.silver_layer.silver_orders_data(
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
loaded_on timestamp default current_timestamp()
);


drop table ECOMMERCE_PIPELINE.silver_layer.silver_orders_data;


select * from silver_orders_data;


(order_id, order_date, customer_id, customer_name, age, gender, region, city,
product_category, product_name, quantity, unit_price, discount_percentage,
sales_amount, profit, shipping_cost, payment_method, customer_satisfaction,
return_flag, order_status, days_to_ship);



CREATE OR REPLACE PROCEDURE auditing_pipeline(
    TABLE_NAME STRING,
    FILE_NAME STRING,
    procedure_name STRING,
    ACTION_TYPE STRING,
    TOTAL_ROWS_READ INT,
    TOTAL_ROWS_INSERTED INT,
    TOTAL_ROWS_UPDATED INT,
    LOADED_TIME_PIPE TIMESTAMP,
    PIPE_STATUS STRING,
    START_TIME TIMESTAMP,
    END_TIME TIMESTAMP,
    ERROR_MESSAGE STRING,
    TO_GET_USER STRING
)
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN

    INSERT INTO ECOMMERCE_PIPELINE.BRONZE_LAYER.AUDIT_TABLE
    (TABLE_NAME,FILE_NAME,procedure_name,ACTION_TYPE,ROWS_READ,ROWS_INSERTED,ROWS_UPDATED,INITIATED_TIME,STATUS,START_TIME,END_TIME,ERROR_MESSAGE,INITIATED_BY)
    VALUES
(:TABLE_NAME,:FILE_NAME,:procedure_name,:ACTION_TYPE,:TOTAL_ROWS_READ,:TOTAL_ROWS_INSERTED,:TOTAL_ROWS_UPDATED,:LOADED_TIME_PIPE,:PIPE_STATUS,:START_TIME,:END_TIME,:ERROR_MESSAGE,:TO_GET_USER);

    RETURN 'Audit Recorded';

END;
$$;





create or replace procedure Transform_Gender_Column()
returns string
language sql
as
$$
declare
TABLE_NAME STRING;
ACTION_TYPE STRING;
PROCEDURE_NAME STRING;
TOTAL_ROWS_READ INT;
TOTAL_ROWS_INSERTED INT;
TOTAL_ROWS_UPDATED INT;
PIPE_STATUS STRING;
START_TIME TIMESTAMP;
END_TIME TIMESTAMP;
TO_GET_USER STRING;
ERROR_MESSAGE STRING;
begin

START_TIME := CURRENT_TIMESTAMP();

TO_GET_USER := current_user();
TABLE_NAME := 'SILVER_ORDERS_DATA';
ACTION_TYPE := 'UPDATE';
PROCEDURE_NAME := 'Transform_gender_column';

select count(*) INTO TOTAL_ROWS_READ from SILVER_ORDERS_DATA;


UPDATE silver_orders_data
SET GENDER = CASE
    WHEN UPPER(TRIM(gender)) IN ('M', 'MALE')
        THEN 'Male'
    WHEN UPPER(TRIM(gender)) IN ('F', 'FEMALE')
        THEN 'Female'
END
WHERE gender IS NOT NULL
  AND UPPER(TRIM(gender)) IN ('M', 'MALE', 'F', 'FEMALE')
  AND gender NOT IN ('Male', 'Female');

TOTAL_ROWS_UPDATED := SQLROWCOUNT;


END_TIME := CURRENT_TIMESTAMP();

call auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, NULL , :TOTAL_ROWS_UPDATED, :START_TIME, 'SUCCESS', :START_TIME, :END_TIME, Null, :TO_GET_USER);

return 'Transformation Completed';

exception
when other then
    END_TIME := CURRENT_TIMESTAMP();
    ERROR_MESSAGE := sqlerrm;
    call auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, NULL , :TOTAL_ROWS_UPDATED, :START_TIME, 'FAILED', :START_TIME, :END_TIME, :sqlerrm, :TO_GET_USER);
    return 'Transformation Failed';
end;
$$;



select * from SILVER_ORDERS_DATA;

call Transform_gender_column();


SELECT * FROM ECOMMERCE_PIPELINE.BRONZE_LAYER.AUDIT_TABLE;


SELECT DISTINCT(order_status) FROM SILVER_ORDERS_DATA;

SELECT DISTINCT(initcap(order_status)) FROM SILVER_ORDERS_DATA;


create or replace procedure Transform_ORDER_STATUS_column()
returns string
language sql
as
$$
declare
TABLE_NAME STRING;
PROCEDURE_NAME STRING;
ACTION_TYPE STRING;
TOTAL_ROWS_READ INT;
TOTAL_ROWS_INSERTED INT;
TOTAL_ROWS_UPDATED INT;
PIPE_STATUS STRING;
START_TIME TIMESTAMP;
END_TIME TIMESTAMP;
TO_GET_USER STRING;
ERROR_MESSAGE STRING;
begin

START_TIME := CURRENT_TIMESTAMP();

TO_GET_USER := current_user();
TABLE_NAME := 'SILVER_ORDERS_DATA';
ACTION_TYPE := 'UPDATE';
PROCEDURE_NAME := 'TRANSFORM_ORDER_STATUS_COLUMN';

select count(*) INTO TOTAL_ROWS_READ from SILVER_ORDERS_DATA;


UPDATE silver_orders_data
SET order_status = CASE
    WHEN UPPER(TRIM(order_status)) IN ('S', 'SHIPPED')
        THEN 'Shipped'
    WHEN UPPER(TRIM(order_status)) IN ('C', 'CANCELLED')
        THEN 'Cancelled'
    WHEN UPPER(TRIM(order_status)) IN ('P', 'PENDING')
        THEN 'Pending'
    WHEN UPPER(TRIM(order_status)) IN ('R', 'RETURNED')
        THEN 'Returned'
    WHEN UPPER(TRIM(order_status)) IN ('D', 'DELIVERED')
        THEN 'Delivered'
END
WHERE order_status IS NOT NULL
  AND UPPER(TRIM(order_status)) IN ('SHIPPED', 'CANCELLED', 'PENDING', 'RETURNED','DELIVERED')
  AND order_status NOT IN ('Shipped', 'Pending', 'Returned', 'Delivered', 'Cancelled');

TOTAL_ROWS_UPDATED := SQLROWCOUNT;


END_TIME := CURRENT_TIMESTAMP();

call auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME, :ACTION_TYPE, :TOTAL_ROWS_READ, NULL , :TOTAL_ROWS_UPDATED, :START_TIME, 'SUCCESS', :START_TIME, :END_TIME, Null, :TO_GET_USER);

return 'Transformation Completed';

exception
when other then
    END_TIME := CURRENT_TIMESTAMP();
    ERROR_MESSAGE := sqlerrm;
    call auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME ,:ACTION_TYPE, :TOTAL_ROWS_READ, NULL , :TOTAL_ROWS_UPDATED, :START_TIME, 'FAILED', :START_TIME, :END_TIME, :sqlerrm, :TO_GET_USER);
    return 'Transformation Failed';
end;
$$;


 CALL  Transform_ORDER_STATUS_column();


 SELECT * FROM ECOMMERCE_PIPELINE.BRONZE_LAYER.AUDIT_TABLE;


SELECT DISTINCT(order_date) FROM SILVER_ORDERS_DATA;


create or replace procedure transform_order_date_column()
returns string
language sql
as
$$
declare
TABLE_NAME STRING;
PROCEDURE_NAME STRING;
ACTION_TYPE STRING;
TOTAL_ROWS_READ INT;
TOTAL_ROWS_INSERTED INT;
TOTAL_ROWS_UPDATED INT;
PIPE_STATUS STRING;
START_TIME TIMESTAMP;
END_TIME TIMESTAMP;
TO_GET_USER STRING;
ERROR_MESSAGE STRING;
begin

START_TIME := CURRENT_TIMESTAMP();

alter table SILVER_ORDERS_DATA add column if not exists new_order_date date;

TO_GET_USER := current_user();
TABLE_NAME := 'SILVER_ORDERS_DATA';
ACTION_TYPE := 'UPDATE';
PROCEDURE_NAME := 'TRANSFORM_ORDER_DATE_COLUMN';

select count(*) INTO TOTAL_ROWS_READ from SILVER_ORDERS_DATA;

 update  SILVER_ORDERS_DATA
        set   new_order_date = case 
        when  order_date  like '%/%'
        then try_to_date( order_date, 'dd/mm/yyyy')
        when  order_date like '%,%'
        then try_to_date( order_date , 'mmmm dd, yyyy') 
        when order_date like '%-%'
        then try_to_date( order_date , 'yyyy-mm-dd')
        else Null
        end;

TOTAL_ROWS_UPDATED := SQLROWCOUNT;


END_TIME := CURRENT_TIMESTAMP();

call auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME, :ACTION_TYPE, :TOTAL_ROWS_READ, NULL , :TOTAL_ROWS_UPDATED, :START_TIME, 'SUCCESS', :START_TIME, :END_TIME, Null, :TO_GET_USER);

return 'Transformation Completed';

exception
when other then
    END_TIME := CURRENT_TIMESTAMP();
    ERROR_MESSAGE := sqlerrm;
    call auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME ,:ACTION_TYPE, :TOTAL_ROWS_READ, NULL , :TOTAL_ROWS_UPDATED, :START_TIME, 'FAILED', :START_TIME, :END_TIME, :sqlerrm, :TO_GET_USER);
    return 'Transformation Failed';
end;
$$;

call transform_order_date_column();


desc table silver_orders_data;


select * from silver_orders_data;

UPDATE SILVER_ORDERS_DATA
SET AGE = NULL
WHERE AGE > 90
   OR AGE < 0;

create or replace procedure transform_age_column()
returns string
language sql
as
$$
declare
TABLE_NAME STRING;
PROCEDURE_NAME STRING;
ACTION_TYPE STRING;
TOTAL_ROWS_READ INT;
TOTAL_ROWS_INSERTED INT;
TOTAL_ROWS_UPDATED INT;
PIPE_STATUS STRING;
START_TIME TIMESTAMP;
END_TIME TIMESTAMP;
TO_GET_USER STRING;
ERROR_MESSAGE STRING;
begin

START_TIME := CURRENT_TIMESTAMP();

TO_GET_USER := current_user();
TABLE_NAME := 'SILVER_ORDERS_DATA';
ACTION_TYPE := 'UPDATE';
PROCEDURE_NAME := 'TRANSFORM_AGE_COLUMN';

select count(*) INTO TOTAL_ROWS_READ from SILVER_ORDERS_DATA;

UPDATE SILVER_ORDERS_DATA
SET AGE = NULL
WHERE AGE > 90
   OR AGE < 0;
 

TOTAL_ROWS_UPDATED := SQLROWCOUNT;


END_TIME := CURRENT_TIMESTAMP();

call auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME, :ACTION_TYPE, :TOTAL_ROWS_READ, NULL , :TOTAL_ROWS_UPDATED, :START_TIME, 'SUCCESS', :START_TIME, :END_TIME, Null, :TO_GET_USER);

return 'Transformation Completed';

exception
when other then
    END_TIME := CURRENT_TIMESTAMP();
    ERROR_MESSAGE := sqlerrm;
    call auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME ,:ACTION_TYPE, :TOTAL_ROWS_READ, NULL , :TOTAL_ROWS_UPDATED, :START_TIME, 'FAILED', :START_TIME, :END_TIME, :sqlerrm, :TO_GET_USER);
    return 'Transformation Failed';
end;
$$;

call transform_age_column();


select age from silver_orders_data where age > 90 or age < 0;

 SELECT * FROM ECOMMERCE_PIPELINE.BRONZE_LAYER.AUDIT_TABLE;


call transform_age_column();
call transform_order_date_column();
CALL  Transform_ORDER_STATUS_column();
call Transform_gender_column();

create or replace procedure Transform_silver_orders_data()
returns string
language sql
as
$$
declare
TABLE_NAME STRING;
PROCEDURE_NAME STRING;
ACTION_TYPE STRING;
START_TIME TIMESTAMP;
TO_GET_USER STRING;
ERROR_MESSAGE STRING;
begin

START_TIME := CURRENT_TIMESTAMP();

TO_GET_USER := 'VIKKURTHI SUBHASH';
TABLE_NAME := 'SILVER_ORDERS_DATA';
ACTION_TYPE := 'UPDATE';
PROCEDURE_NAME := 'Transform_silver_orders_data';

    call transform_age_column();
    call transform_order_date_column();
    CALL  Transform_ORDER_STATUS_column();
    call Transform_gender_column();

CALL SYSTEM$SEND_EMAIL(
    'alert_user',
    'subhashv9966@gmail.com',
    'Regarding_MicroBatchin_Pipeline',
    'FROM_USER : ' || :TO_GET_USER || CHAR(10) ||
    'TABLE_NAME : ' || :TABLE_NAME || CHAR(10) ||
    'PROCEDURE_NAME : ' || :PROCEDURE_NAME || CHAR(10) ||
    'ERROR_MESSAGE : ' || 'NULL' || CHAR(10) ||
    'STATUS : ' || 'SUCCESS');

    return 'Transformed Sucessfully';

exception
when other then
    ERROR_MESSAGE := sqlerrm;

    CALL SYSTEM$SEND_EMAIL(
    'alert_user',
    'subhashv9966@gmail.com',
    'Regarding_MicroBatchin_Pipeline',
    'FROM_USER : ' || :TO_GET_USER || CHAR(10) ||
    'TABLE_NAME : ' || :TABLE_NAME || CHAR(10) ||
    'PROCEDURE_NAME : ' || :PROCEDURE_NAME || CHAR(10) ||
    'ERROR_MESSAGE : ' || COALESCE(:sqlerrm, 'NA') || CHAR(10) ||
    'STATUS : ' || 'FAILED');

        return 'Transformation Failed';


end;
$$;

call Transform_silver_orders_data();

select * from silver_orders_data;

-- create a stream over silver_table
--when stream have data
--  task 1(transform data)
-- task 2(insert to staging table)(stream consumed)
-- update snapshot
-- insert to fact & dim tables
-- truncate silver staging table if suceed


select *  from silver_orders_data limit 10;

select * from silver_orders_data;

select * from ecommerce_pipeline.bronze_layer.audit_table;


-- Procedure to consume silver_stagging

create or replace procedure migrating_to_silver_staging()
returns string
language sql
as
$$
begin

    INSERT INTO silver_stagging
    SELECT *
    FROM silver_orders_stream;

end;
$$;
;;

create or replace procedure migrating_to_silver_staging()
returns string
language sql
as
$$
declare
TABLE_NAME STRING;
FILE_NAME STRING;
procedure_name STRING;
ACTION_TYPE STRING;
TOTAL_ROWS_READ INT;
TOTAL_ROWS_INSERTED INT;
TOTAL_ROWS_UPDATED INT default 0;
LOADED_TIME_PIPE TIMESTAMP;
PIPE_STATUS STRING;
START_TIME TIMESTAMP;
END_TIME TIMESTAMP;
TO_GET_USER STRING;
ERROR_MESSAGE STRING;
begin 

START_TIME := CURRENT_TIMESTAMP();
TO_GET_USER := 'VIKKURTHI_SUBHASH';
TABLE_NAME := 'SILVER_STAGING';
ACTION_TYPE := 'INSERT';
PROCEDURE_NAME := 'MIGRATING_TO_SILVER_STAGING';
select count(*) INTO TOTAL_ROWS_READ from Silver_orders_stream_;

    INSERT INTO silver_stagging
    SELECT *
    FROM Silver_orders_stream_;

TOTAL_ROWS_INSERTED := sqlrowcount;

END_TIME := CURRENT_TIMESTAMP();

call ecommerce_pipeline.silver_layer.auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, :TOTAL_ROWS_INSERTED , :TOTAL_ROWS_UPDATED, NULL, 'SUCCESS', :START_TIME, :END_TIME, Null, :TO_GET_USER);

return 'SUCCESS_FULLY CONSUMED';

exception
when other then
    END_TIME := CURRENT_TIMESTAMP();
    ERROR_MESSAGE := sqlerrm;
    call ecommerce_pipeline.silver_layer.auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, :TOTAL_ROWS_INSERTED , :TOTAL_ROWS_UPDATED, NULL, 'FAILED', :START_TIME, :END_TIME, :sqlerrm, :TO_GET_USER); 
    
    return 'FAILED TO CONSUME' || :sqlerrm ;

end;
$$;

CALL migrating_to_silver_staging();


-- TO TRUNCATE STAGGING TABLE
create or replace procedure To_TRUNCATE_SILVER_STAGING_TABLE()
returns string
language sql
as
$$
declare
TABLE_NAME STRING;
FILE_NAME STRING;
procedure_name STRING;
ACTION_TYPE STRING;
TOTAL_ROWS_READ INT;
TOTAL_ROWS_INSERTED INT default 0;
TOTAL_ROWS_UPDATED INT default 0;
LOADED_TIME_PIPE TIMESTAMP;
PIPE_STATUS STRING;
START_TIME TIMESTAMP;
END_TIME TIMESTAMP;
TO_GET_USER STRING;
ERROR_MESSAGE STRING;
begin 

START_TIME := CURRENT_TIMESTAMP();
TO_GET_USER := 'VIKKURTHI_SUBHASH';
TABLE_NAME := 'SILVER_STAGGING';
ACTION_TYPE := 'DELETE';
PROCEDURE_NAME := 'To_TRUNCATE_SILVER_STAGING_TABLE';
select count(*) INTO TOTAL_ROWS_READ from SILVER_STAGGING;

        Truncate table SILVER_STAGGING;



END_TIME := CURRENT_TIMESTAMP();

call ecommerce_pipeline.silver_layer.auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, :TOTAL_ROWS_INSERTED , :TOTAL_ROWS_UPDATED, NULL, 'SUCCESS', :START_TIME, :END_TIME, Null, :TO_GET_USER);

return 'SUCCESSFULLY TRUNCATED';

exception
when other then
    END_TIME := CURRENT_TIMESTAMP();
    ERROR_MESSAGE := sqlerrm;
    call ecommerce_pipeline.silver_layer.auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, :TOTAL_ROWS_INSERTED , :TOTAL_ROWS_UPDATED, NULL, 'FAILED', :START_TIME, :END_TIME, :sqlerrm, :TO_GET_USER); 
    
    return ':FAILED TO TRUNCATE' || :sqlerrm ;


end;
$$;

CALL To_TRUNCATE_SILVER_STAGING_TABLE();


SELECT * FROM SILVER_STAGGING;


SELECT GET_DDL('PROCEDURE','call ecommerce_pipeline.silver_layer.auditing_pipeline');


DESC TABLE SILVER_STAGGING;
