import json
import os
import boto3
import snowflake.connector

sm = boto3.client("secretsmanager", region_name="us-east-1")
bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")

MODEL_ID = "amazon.nova-micro-v1:0"


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


def fetch_context():
    conn = get_snowflake_conn()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT account_id, industry, tier, health_score, is_churned,
               total_sessions, features_adopted, error_rate, days_since_last_active,
               avg_sentiment, support_ticket_count, top_complaint_category
        FROM ACCOUNT_HEALTH_SCORE
        ORDER BY health_score ASC
    """)
    columns = [desc[0] for desc in cursor.description]
    rows = cursor.fetchall()

    accounts = []
    for row in rows:
        accounts.append(dict(zip(columns, row)))

    cursor.close()
    conn.close()
    return accounts


def build_prompt(question, accounts):
    summary = json.dumps(accounts, default=str, indent=2)

    return f"""You are an analytics assistant for VantagePoint, a B2B SaaS platform.
Below is the customer health data for all accounts, including health scores (0-100),
usage metrics, sentiment scores, and complaint categories.

Health Score Tiers: 65+ = healthy, 40-64 = at_risk, below 40 = critical.

CUSTOMER DATA:
{summary}

Based on this data, answer the following question clearly and concisely.
Include specific account IDs and numbers where relevant.

QUESTION: {question}"""


def lambda_handler(event, context):
    body = json.loads(event.get("body", "{}"))
    question = body.get("query")

    if not question:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": "Missing query"})
        }

    accounts = fetch_context()
    prompt = build_prompt(question, accounts)

    response = bedrock.invoke_model(
        modelId=MODEL_ID,
        contentType="application/json",
        accept="application/json",
        body=json.dumps({
            "messages": [{"role": "user", "content": [{"text": prompt}]}],
            "inferenceConfig": {"maxTokens": 1024, "temperature": 0.1}
        })
    )

    result = json.loads(response["body"].read())
    answer = result["output"]["message"]["content"][0]["text"]

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
        "body": json.dumps({"answer": answer})
    }