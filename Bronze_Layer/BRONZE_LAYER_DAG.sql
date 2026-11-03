-- Parent_Task
create or replace task Auditing_Bronze_table
    warehouse = compute_wh
    TASK_AUTO_RETRY_ATTEMPTS = 2
    SUSPEND_TASK_AFTER_NUM_FAILURES = 2
    when system$stream_has_data('TO_MERGE_SILVER')
    as
    call AUDITING_AND_NOTIFICATION_BRONZE();


--Child Task to Consume_Stream
create or replace task To_Consume_Stream
    warehouse = compute_wh
    after Auditing_Bronze_table
    as
    call migrating_to_staging();




--Merge Into Silver_Layer_Table
create or replace task Merger_into_Target_Table
    warehouse = compute_wh
    after To_Consume_Stream
    as
    call DATA_LOADING_TO_SILVER_ORDERS_TABLE();



-- To Truncate Stagging Table
create or replace task Tuncate_Stagging_Table
    warehouse = compute_wh
    after Merger_into_Target_Table
    as
    call Truncate_Existing_STAGING();


    -- 1. Resume the last child task
ALTER TASK Tuncate_Stagging_Table RESUME;

-- 2. Resume the third task
ALTER TASK Merger_into_Target_Table RESUME;



-- 3. Resume the second task
ALTER TASK To_Consume_Stream RESUME;

-- 4. Resume the parent task (always last)
ALTER TASK AUDITING_BRONZE_TABLE RESUME;


SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        SCHEDULED_TIME_RANGE_START =>
            DATEADD('DAY', -1, CURRENT_TIMESTAMP())
    )
)
WHERE NAME = 'Merger_into_Target_Table'
ORDER BY SCHEDULED_TIME DESC;


SELECT GET_DDL('PROCEDURE',
    'Truncate_Existing_STAGING()');


  -- 1. Resume the last child task
ALTER TASK Tuncate_Stagging_Table SUSPEND;

-- 2. Resume the third task
ALTER TASK Merger_into_Target_Table SUSPEND;



-- 3. Resume the second task
ALTER TASK To_Consume_Stream SUSPEND;

-- 4. Resume the parent task (always last)
ALTER TASK Auditing_Bronze_table SUSPEND;


SHOW TASKS;

select count(*) from bronze_orders_data;

select * from bronze_staging;


select * from audit_table;