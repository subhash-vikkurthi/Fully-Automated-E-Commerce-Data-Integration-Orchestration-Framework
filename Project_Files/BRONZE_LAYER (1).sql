create schema bronze_layer;


-- snowpipe to Auto_IngestData

CREATE OR REPLACE PIPE orders_pipe
AUTO_INGEST = TRUE
AWS_SNS_TOPIC = 'arn:aws:sns:eu-north-1:660169747130:snowpipe2'
AS
COPY INTO ECOMMERCE_PIPELINE.bronze_layer.bronze_orders_data
(order_id, order_date, customer_id, customer_name, age, gender, region, city,
product_category, product_name, quantity, unit_price, discount_percentage,
sales_amount, profit, shipping_cost, payment_method, customer_satisfaction,
return_flag, order_status, days_to_ship)
FROM @RESOURCE_LAYER.MY_S3_STAGE
PATTERN = '.*orders.*[.]csv'
FILE_FORMAT = (FORMAT_NAME = RESOURCE_LAYER.csv_format);

-- for sns trustpolicy

SELECT SYSTEM$GET_AWS_SNS_IAM_POLICY('arn:aws:sns:eu-north-1:660169747130:snowpipe2');

-- To Check Pipe Details

select system$pipe_status('orders_pipe');

-- check the bronze_table

select * from bronze_orders_data;


-- Audit_Recording Procedure
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

-- TO CHECK SNOWPIPE COPY_HISTORY

SELECT
    *
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'bronze_orders_data',
        START_TIME => DATEADD('DAY', -7, CURRENT_TIMESTAMP())
    )
);


-- Creating Stream on Bronze_orders_data

create or replace stream  To_merge_silver on table ecommerce_pipeline.bronze_layer.bronze_orders_data;


CREATE OR REPLACE PROCEDURE AUDITING_AND_NOTIFICATION_BRONZE()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
TABLE_NAME STRING;
FILE_NAME STRING;
TOTAL_ROWS_READ INT;
TOTAL_ROWS_INSERTED INT;
TOTAL_ROWS_UPDATED INT default 0;
error_message_pipe string;
loaded_time_pipe datetime;
TO_GET_USER STRING;
pipe_status string;
ACTION_TYPE STRING;
PROCEDURE_NAME STRING;
Total_errors int;
BEGIN
        

        TO_GET_USER := 'SUBHASH_VIKKURTHI';

        PROCEDURE_NAME := 'AUDITING_AND_NOTIFICATION_BRONZE';

        ACTION_TYPE := 'Data_Loading';

        SELECT TABLE_NAME,FILE_NAME,ROW_COUNT,ROW_PARSED,ERROR_COUNT,FIRST_ERROR_MESSAGE,last_load_time,CASE
        WHEN upper(STATUS) = 'LOADED' THEN 'SUCCESS'
        WHEN upper(STATUS) = 'LOAD_FAILED' THEN 'FAILED'
        WHEN upper(STATUS) = 'PARTIALLY_LOADED' THEN 'PARTIAL_SUCCESS'
        ELSE STATUS END AS STATUS 
        into TABLE_NAME,FILE_NAME,TOTAL_ROWS_INSERTED,TOTAL_ROWS_READ,Total_errors,error_message_pipe,loaded_time_pipe,pipe_status
        FROM TABLE(
        INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'bronze_orders_data',
        START_TIME => DATEADD('DAY', -7, CURRENT_TIMESTAMP())
        )) order by last_load_time desc
        limit 1;


        call ecommerce_pipeline.silver_layer.auditing_pipeline(:TABLE_NAME,:FILE_NAME,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, :TOTAL_ROWS_INSERTED , :TOTAL_ROWS_UPDATED, :loaded_time_pipe, :pipe_status, NULL, NULL, :error_message_pipe, :TO_GET_USER);


        CALL SYSTEM$SEND_EMAIL(
    'alert_user',
    'subhashv9966@gmail.com',
    'Regarding_MicroBatching_Pipeline',
    'FROM_USER : ' || :TO_GET_USER || CHAR(10) ||
    'TABLE_NAME : ' || :TABLE_NAME || CHAR(10) ||
    'FILE_NAME : ' || :FILE_NAME || CHAR(10) ||
    'NO_OF_ROWS_LOADED : ' || :TOTAL_ROWS_INSERTED || CHAR(10) ||
    'NO_OF_ROWS_PARSED : ' || :TOTAL_ROWS_READ || CHAR(10) ||
    'ERROR_MESSAGE : ' || COALESCE(:error_message_pipe, 'NA') || CHAR(10) ||
    'STATUS : ' || :pipe_status);

        RETURN 'SUCCESSFULLY COMPLETED';

EXCEPTION

    WHEN OTHER THEN

        RETURN 'PROCEDURE FAILED: ' || SQLERRM;
END;
$$;

-- check the Columns

select * from BRONZE_STAGING;

create or replace procedure migrating_to_staging()
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
TABLE_NAME := 'BRONZE_STAGING';
ACTION_TYPE := 'INSERT';
PROCEDURE_NAME := 'MIGRATING_TO_STAGING';
select count(*) INTO TOTAL_ROWS_READ from TO_MERGE_SILVER;

    INSERT INTO BRONZE_STAGING
    SELECT *
    FROM TO_MERGE_SILVER;

TOTAL_ROWS_INSERTED := sqlrowcount;

END_TIME := CURRENT_TIMESTAMP();

call ecommerce_pipeline.silver_layer.auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, :TOTAL_ROWS_INSERTED , :TOTAL_ROWS_UPDATED, NULL, 'SUCCESS', :START_TIME, :END_TIME, Null, :TO_GET_USER);

return ':SUCCESS';

exception
when other then
    END_TIME := CURRENT_TIMESTAMP();
    ERROR_MESSAGE := sqlerrm;
    call ecommerce_pipeline.silver_layer.auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, :TOTAL_ROWS_INSERTED , :TOTAL_ROWS_UPDATED, NULL, 'FAILED', :START_TIME, :END_TIME, :sqlerrm, :TO_GET_USER); 
    
    return ':FAILED';

end;
$$;


-- TO TRUNCATE STAGGING TABLE
create or replace procedure To_TRUNCATE_BRONZE_STAGING_TABLE()
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
TABLE_NAME := 'BRONZE_STAGING';
ACTION_TYPE := 'DELETE';
PROCEDURE_NAME := 'To_TRUNCATE_BRONZE_STAGING_TABLE';
select count(*) INTO TOTAL_ROWS_READ from TO_MERGE_SILVER;

        Truncate table BRONZE_STAGING;



END_TIME := CURRENT_TIMESTAMP();

call ecommerce_pipeline.silver_layer.auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, :TOTAL_ROWS_INSERTED , :TOTAL_ROWS_UPDATED, NULL, 'SUCCESS', :START_TIME, :END_TIME, Null, :TO_GET_USER);

return ':SUCCESSFULLY TRUNCATED';

exception
when other then
    END_TIME := CURRENT_TIMESTAMP();
    ERROR_MESSAGE := sqlerrm;
    call ecommerce_pipeline.silver_layer.auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, :TOTAL_ROWS_INSERTED , :TOTAL_ROWS_UPDATED, NULL, 'FAILED', :START_TIME, :END_TIME, :sqlerrm, :TO_GET_USER); 
    
    return 'FAILED TO TUNCATE' || :SQLerrm;


end;
$$;


CALL To_Truncate_STAGING_TABLE();

select * from BRONZE_STAGING;

create or replace procedure DATA_LOADING_TO_SILVER_ORDERS_TABLE()
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
TABLE_NAME := 'SILVER_ORDERS_DATA';
ACTION_TYPE := 'INSERT';
PROCEDURE_NAME := 'DATA_LOADING_TO_SILVER_ORDERS_TABLE';
select count(*) INTO TOTAL_ROWS_READ from SILVER_ORDERS_DATA;


MERGE INTO ecommerce_pipeline.silver_layer.silver_orders_data AS target
USING (select
order_id, order_date, customer_id, customer_name, age, gender, region, city,
product_category, product_name, quantity, unit_price, discount_percentage,
sales_amount, profit, shipping_cost, payment_method, customer_satisfaction,
return_flag, order_status, days_to_ship,loaded_time,METADATA$ACTION,METADATA$ISUPDATE from ecommerce_pipeline.bronze_layer.BRONZE_STAGING
where METADATA$ACTION = 'INSERT'
qualify row_number() over(partition by order_id order by loaded_time desc) = 1) as source_new
    ON source_new.order_id = target.order_id

WHEN MATCHED
    AND source_new.METADATA$ACTION = 'DELETE'
    AND source_new.METADATA$ISUPDATE = FALSE
THEN DELETE

WHEN MATCHED
    AND source_new.METADATA$ACTION = 'INSERT'
THEN UPDATE SET
    target.order_id = source_new.order_id,
    target.order_date = source_new.order_date,
    target.customer_id = source_new.customer_id,
    target.customer_name = source_new.customer_name,
    target.age = source_new.age,
    target.gender = source_new.gender,
    target.region = source_new.region,
    target.city = source_new.city,
    target.product_category = source_new.product_category,
    target.product_name = source_new.product_name,
    target.quantity = source_new.quantity,
    target.unit_price = source_new.unit_price,
    target.discount_percentage = source_new.discount_percentage,
    target.sales_amount = source_new.sales_amount,
    target.profit = source_new.profit,
    target.shipping_cost = source_new.shipping_cost,
    target.payment_method = source_new.payment_method,
    target.customer_satisfaction = source_new.customer_satisfaction,
    target.return_flag = source_new.return_flag,
    target.order_status = source_new.order_status,
    target.days_to_ship = source_new.days_to_ship
    

WHEN NOT MATCHED
    AND source_new.METADATA$ACTION = 'INSERT'
THEN INSERT(order_id,order_date,customer_id,customer_name,age,gender,region,city,product_category,product_name,quantity,unit_price,discount_percentage,sales_amount,profit,shipping_cost,payment_method,customer_satisfaction,return_flag,order_status,days_to_ship)
VALUES (source_new.order_id,source_new.order_date,source_new.customer_id,source_new.customer_name,source_new.age,source_new.gender,source_new.region,source_new.city,source_new.product_category,source_new.product_name,source_new.quantity,source_new.unit_price,source_new.discount_percentage,source_new.sales_amount,source_new.profit,source_new.shipping_cost,source_new.payment_method,source_new.customer_satisfaction,source_new.return_flag,source_new.order_status,source_new.days_to_ship);


TOTAL_ROWS_INSERTED := sqlrowcount;

END_TIME := CURRENT_TIMESTAMP();

call ecommerce_pipeline.silver_layer.auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, :TOTAL_ROWS_INSERTED , :TOTAL_ROWS_UPDATED, :START_TIME, 'SUCCESS', :START_TIME, :END_TIME, Null, :TO_GET_USER);


 CALL SYSTEM$SEND_EMAIL(
    'alert_user',
    'subhashv9966@gmail.com',
    'Regarding_MicroBatching_Pipeline',
    'FROM_USER : ' || :TO_GET_USER || CHAR(10) ||
    'TABLE_NAME : ' || :TABLE_NAME || CHAR(10) ||
    'NO_OF_ROWS_LOADED : ' || :TOTAL_ROWS_INSERTED || CHAR(10) ||
    'NO_OF_ROWS_PARSED : ' || :TOTAL_ROWS_READ || CHAR(10) ||
    'ERROR_MESSAGE :  NA' || CHAR(10) ||
    'STATUS : SUCCESS');

return 'LOADING Completed SUCESSFULLY';

exception
when other then
    END_TIME := CURRENT_TIMESTAMP();
    ERROR_MESSAGE := sqlerrm;
    call ecommerce_pipeline.silver_layer.auditing_pipeline(:TABLE_NAME, NULL,:PROCEDURE_NAME , :ACTION_TYPE, :TOTAL_ROWS_READ, :TOTAL_ROWS_INSERTED , :TOTAL_ROWS_UPDATED, :START_TIME, 'FAILED', :START_TIME, :END_TIME, :sqlerrm, :TO_GET_USER);
    
 CALL SYSTEM$SEND_EMAIL(
    'alert_user',
    'subhashv9966@gmail.com',
    'Regarding_MicroBatching_Pipeline',
    'FROM_USER : ' || :TO_GET_USER || CHAR(10) ||
    'TABLE_NAME : ' || :TABLE_NAME || CHAR(10) ||
    'NO_OF_ROWS_LOADED : ' || :TOTAL_ROWS_INSERTED || CHAR(10) ||
    'NO_OF_ROWS_PARSED : ' || :TOTAL_ROWS_READ || CHAR(10) ||
    'ERROR_MESSAGE : ' || :ERROR_MESSAGE || CHAR(10) ||
    'STATUS : FAILED');
    
    return 'LOADING Failed';


end;
$$;

CALL DATA_LOADING_TO_SILVER_ORDERS_TABLE();

select * from audit_table;


create or replace procedure Truncate_Existing_STAGING()
returns string
language sql
as
$$
begin

    Truncate table BRONZE_STAGING;


end;
$$;



SELECT * FROM BRONZE_STAGING;


SELECT * FROM AUDIT_TABLE;


select * from bronze_orders_data;



select * from to_merge_silver;


select get_ddl('procedure','To_Truncate_STAGING_TABLE');






