import boto3
import json
import os
import snowflake.connector

s3 = boto3.client("s3")
sm = boto3.client("secretsmanager", region_name="us-east-1")
bedrock = boto3.client("bedrock-runtime", region_name="us-east-1")

MODEL_ID = "amazon.nova-micro-v1:0"

PROMPT_TEMPLATE = """Analyze the following customer interaction transcript.
Return a JSON object with exactly two fields:
1. "sentiment_score": a float between -1.0 (very negative) and 1.0 (very positive)
2. "complaint_category": one of these categories ONLY: "billing", "performance", "bugs", "feature_request", "onboarding", "security", "data_quality", "general"

If the interaction is a sales call or positive email, still assign a sentiment score and use "general" as the category if no complaint exists.

Return ONLY the JSON object, no other text.

Transcript:
{transcript}"""


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


def analyze_transcript(transcript_body):
    prompt = PROMPT_TEMPLATE.format(transcript=transcript_body)

    body = json.dumps({
        "messages": [{"role": "user", "content": [{"text": prompt}]}],
        "inferenceConfig": {
            "maxTokens": 150,
            "temperature": 0.1
        }
    })

    response = bedrock.invoke_model(
        modelId=MODEL_ID,
        contentType="application/json",
        accept="application/json",
        body=body
    )

    result = json.loads(response["body"].read())
    text = result["output"]["message"]["content"][0]["text"]

    try:
        analysis = json.loads(text.strip())
        score = float(analysis.get("sentiment_score", 0.0))
        category = analysis.get("complaint_category", "general")
    except (json.JSONDecodeError, ValueError):
        score = 0.0
        category = "general"

    return score, category


def lambda_handler(event, context):
    bucket = event["bucket"]
    key = event["key"]

    response = s3.get_object(Bucket=bucket, Key=key)
    content = response["Body"].read().decode("utf-8")

    records = []
    for line in content.strip().split("\n"):
        if line.strip():
            records.append(json.loads(line))

    print(f"Processing {len(records)} transcripts from {key}")

    conn = get_snowflake_conn()
    cursor = conn.cursor()

    insert_sql = """
        INSERT INTO INTERACTION_TRANSCRIPTS 
        (INTERACTION_ID, ACCOUNT_ID, OPPORTUNITY_ID, TIMESTAMP, 
         INTERACTION_TYPE, TRANSCRIPT_BODY, SENTIMENT_SCORE, COMPLAINT_CATEGORY)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """

    processed = 0
    for record in records:
        score, category = analyze_transcript(record["transcript_body"])

        cursor.execute(insert_sql, (
            record["interaction_id"],
            record.get("account_id"),
            record.get("opportunity_id"),
            record["timestamp"],
            record["interaction_type"],
            record["transcript_body"],
            score,
            category
        ))
        processed += 1

    conn.commit()
    cursor.close()
    conn.close()

    print(f"Inserted {processed} enriched transcripts from {key}")
    return {"file": key, "records_processed": processed}