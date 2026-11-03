create database ecommerce_pipeline;

create or replace schema resource_layer;

-- Storage Integration --AWS

create or replace storage integration Integrate_S3
enabled = TRUE
storage_provider = s3
type = external_stage
storage_aws_role_arn = 'YOUR-ROLE-ARN'
storage_allowed_locations = ('S3-URL');

desc storage integration Integrate_S3;

-- Fileformat(for Schema evolution)

CREATE OR REPLACE FILE FORMAT csv_format
TYPE = CSV
skip_header = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"';

CREATE STAGE my_s3_stage
  URL = 'S3-URL'
  STORAGE_INTEGRATION = Integrate_S3
  FILE_FORMAT = csv_format;


  list @my_s3_stage;

  create or replace notification integration alert_user
  type = email
  enabled = True
  allowed_recipients = ('YOUR-MAIL@gmail.com')
  default_subject = 'Regarding_MicroBatching_Pipeline';
