import sys
import json
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.context import SparkContext
from pyspark.sql.functions import col, to_timestamp

args = getResolvedOptions(sys.argv, ["JOB_NAME", "SECRET_NAME", "DATA_LAKE_BUCKET"])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# fetch snowflake creds from secrets manager
sm = boto3.client("secretsmanager", region_name="us-east-1")
secret = json.loads(sm.get_secret_value(SecretId=args["SECRET_NAME"])["SecretString"])

sf_options = {
    "sfURL": f"{secret['account']}.snowflakecomputing.com",
    "sfUser": secret["username"],
    "sfPassword": secret["password"],
    "sfDatabase": "VANTAGEPOINT_PROD",
    "sfSchema": "B2BSAAS",
    "sfWarehouse": "VANTAGEPOINT_WH"
}

# read usage logs from S3 as DynamicFrame
bucket = args["DATA_LAKE_BUCKET"]
source_path = f"s3://{bucket}/raw/usage_logs/"

dynamic_frame = glueContext.create_dynamic_frame.from_options(
    connection_type="s3",
    connection_options={"paths": [source_path], "recurse": True},
    format="json"
)

# convert to pyspark dataframe for transformations
df = dynamic_frame.toDF()

# transform and rename columns to match Snowflake table
df = df.select(
    col("session_id").alias("SESSION_ID"),
    col("account_id").alias("ACCOUNT_ID"),
    col("user_id").alias("USER_ID"),
    col("feature_used").alias("FEATURE_USED"),
    col("session_duration_seconds").cast("int").alias("SESSION_DURATION_SECONDS"),
    col("error_codes_encountered").alias("ERROR_CODES_ENCOUNTERED"),
    to_timestamp(col("timestamp")).alias("TIMESTAMP")
)

# deduplicate on session_id
df = df.dropDuplicates(["SESSION_ID"])

# drop rows missing required fields
df = df.filter(col("SESSION_ID").isNotNull() & col("ACCOUNT_ID").isNotNull())

# write to snowflake
df.write \
    .format("net.snowflake.spark.snowflake") \
    .options(**sf_options) \
    .option("dbtable", "USAGE_LOGS") \
    .mode("append") \
    .save()

job.commit()