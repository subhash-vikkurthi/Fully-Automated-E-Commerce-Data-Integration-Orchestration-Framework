create or replace stream Silver_orders_stream_ on table ECOMMERCE_PIPELINE.silver_layer.silver_orders_data;


SELECT * FROM Silver_orders_stream_;

-- Parent_Task
-- creating task to transform silver_layer data

create or replace task Transform_Silver_Table_Data_
    warehouse = compute_wh
    TASK_AUTO_RETRY_ATTEMPTS = 2
    SUSPEND_TASK_AFTER_NUM_FAILURES = 2
    WHEN SYSTEM$STREAM_HAS_DATA('Silver_orders_stream_')
    
    AS 
    CALL Transform_silver_orders_data();


--Child Task to Consume_Stream

create or replace task To_Consume_Silver_Stream
    warehouse = compute_wh
    after Transform_Silver_Table_Data_
    as
    call migrating_to_silver_staging();


--Merge Into Silver_Layer_Table


create or replace task DESIGN_STAR_SCHEMA
    warehouse = compute_wh
    after To_Consume_Silver_Stream
    as
    CALL   ECOMMERCE_PIPELINE.GOLD_LAYER.TO_DESIGN_GOLD_SCHEMA();


-- TO AUTO ENABLE TASKS
SELECT SYSTEM$TASK_DEPENDENTS_ENABLE(
    'ECOMMERCE_PIPELINE.SILVER_LAYER.Transform_Silver_Table_Data'
);

-- TO CHECK TASK HISTORY
SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        SCHEDULED_TIME_RANGE_START =>
            DATEADD('DAY', -1, CURRENT_TIMESTAMP())
    )
)
WHERE NAME = 'TRANSFORM_SILVER_TABLE_DATA_'
ORDER BY SCHEDULED_TIME DESC;


-- To Truncate Stagging Table
create or replace task Tuncate_Stagging_Table
    warehouse = compute_wh
    after DESIGN_STAR_SCHEMA
    as
    call To_TRUNCATE_SILVER_STAGING_TABLE();


-- Resume Task DAG
Alter task Tuncate_Stagging_Table resume;

Alter task DESIGN_STAR_SCHEMA resume;

Alter task To_Consume_Silver_Stream resume;

ALTER TASK Transform_Silver_Table_Data_ RESUME;

-- TO SUSPEND TASK DAG
ALTER TASK Transform_Silver_Table_Data_ suspend;


Alter task To_Consume_Silver_Stream suspend;


Alter task DESIGN_STAR_SCHEMA suspend;


Alter task Tuncate_Stagging_Table suspend;


SHOW TASKS;