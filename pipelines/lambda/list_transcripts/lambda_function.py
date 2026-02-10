import boto3
import os

s3 = boto3.client("s3")

def lambda_handler(event, context):
    bucket = os.environ["DATA_LAKE_BUCKET"]
    prefix = "raw/transcripts/"

    files = []
    paginator = s3.get_paginator("list_objects_v2")

    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        for obj in page.get("Contents", []):
            if obj["Key"].endswith(".json"):
                files.append({
                    "bucket": bucket,
                    "key": obj["Key"]
                })

    print(f"Found {len(files)} transcript files")
    return {"files": files}