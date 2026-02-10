import json
import os
import boto3
import snowflake.connector

sm = boto3.client("secretsmanager", region_name="us-east-1")


def get_snowflake_conn():
    secret = json.loads(
        sm.get_secret_value(SecretId=os.environ["SECRET_NAME"])["SecretString"]
    )
    return snowflake.connector.connect(
        user=secret["username"],
        password=secret["password"],
        account=secret["account"],
        warehouse="VANTAGEPOINT_WH",
        database="VANTAGEPOINT_PROD",
        schema="B2BSAAS"
    )


def lambda_handler(event, context):
    account_id = event.get("pathParameters", {}).get("account_id")

    if not account_id:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": "Missing account_id"})
        }

    conn = get_snowflake_conn()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT interaction_id, account_id, opportunity_id, timestamp,
               interaction_type, transcript_body, sentiment_score, complaint_category
        FROM INTERACTION_TRANSCRIPTS
        WHERE account_id = %s
        ORDER BY timestamp DESC
    """, (account_id,))

    columns = [desc[0] for desc in cursor.description]
    rows = cursor.fetchall()

    transcripts = []
    for row in rows:
        record = dict(zip(columns, row))
        record["SENTIMENT_SCORE"] = float(record["SENTIMENT_SCORE"]) if record["SENTIMENT_SCORE"] else 0
        transcripts.append(record)

    cursor.close()
    conn.close()

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
        "body": json.dumps({"transcripts": transcripts}, default=str)
    }