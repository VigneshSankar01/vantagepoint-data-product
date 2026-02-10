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
    conn = get_snowflake_conn()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT account_id, industry, tier, annual_revenue, is_churned,
               tenure_days, health_score, total_sessions, active_users,
               features_adopted, avg_session_duration, error_rate,
               days_since_last_active, avg_sentiment, support_ticket_count,
               negative_interaction_count, top_complaint_category
        FROM ACCOUNT_HEALTH_SCORE
        ORDER BY health_score ASC
    """)

    columns = [desc[0] for desc in cursor.description]
    rows = cursor.fetchall()

    accounts = []
    for row in rows:
        record = dict(zip(columns, row))
        record["ANNUAL_REVENUE"] = float(record["ANNUAL_REVENUE"]) if record["ANNUAL_REVENUE"] else 0
        record["HEALTH_SCORE"] = float(record["HEALTH_SCORE"]) if record["HEALTH_SCORE"] else 0
        record["AVG_SESSION_DURATION"] = float(record["AVG_SESSION_DURATION"]) if record["AVG_SESSION_DURATION"] else 0
        record["ERROR_RATE"] = float(record["ERROR_RATE"]) if record["ERROR_RATE"] else 0
        record["AVG_SENTIMENT"] = float(record["AVG_SENTIMENT"]) if record["AVG_SENTIMENT"] else 0
        accounts.append(record)

    cursor.close()
    conn.close()

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
        "body": json.dumps({"accounts": accounts}, default=str)
    }