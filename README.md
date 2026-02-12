# VantagePoint Customer Intelligence Platform

A strategic data product that unifies CRM, platform usage, and customer interaction data to give B2B SaaS leadership a clear, actionable view of portfolio health — replacing gut feel with data-driven intelligence.

**Live App:** [https://master.d2atukzvz8yx18.amplifyapp.com](https://master.d2atukzvz8yx18.amplifyapp.com)

---

## The Problem

VantagePoint, a rapidly scaling B2B SaaS platform, has customer data scattered across three isolated systems: CRM (sales & subscriptions), platform usage logs, and customer interaction transcripts. The executive team is "flying blind" — they can't see which accounts are healthy, which are about to churn, or why.

## The Solution

The **Customer Intelligence Platform** breaks down these silos by ingesting all three data sources into a unified warehouse, computing a composite **Account Health Score (0–100)** per account, and surfacing it through an authenticated web dashboard with AI-powered recommendations.

The platform answers one core question: **Which accounts are at risk, and what should we do about them?**

### Key Features

- **Account Health Scoring** — Composite 0–100 score combining usage metrics, sentiment analysis, and support signals
- **Risk Tiering** — Automatic classification into Healthy (65+), At Risk (40–64), Critical (<40), and Churned
- **AI-Assisted Recommendations** — Per-account actionable advice powered by Amazon Bedrock (Nova Micro)
- **AI Transcript Summaries** — Natural language synthesis of all customer interactions per account
- **Sortable & Filterable Dashboard** — Search, filter by risk tier or industry, sort by any column
- **Expandable Drill-Down** — Click any account to see signal cards, AI insights, and raw transcript records
- **JWT Authentication** — Secured via Amazon Cognito, only authenticated users can access data

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| **Data Warehouse** | Snowflake (XSMALL warehouse, auto-suspend 60s, auto-resume) |
| **Cloud Infrastructure** | AWS (S3, Lambda, Glue, Step Functions, API Gateway, Secrets Manager, VPC, NAT Gateway) |
| **AI/ML** | Amazon Bedrock (Nova Micro) — sentiment classification, recommendations, summarization |
| **Transformations** | dbt Core (7 models: staging → intermediate → marts) |
| **Infrastructure as Code** | Terraform with S3 remote backend + DynamoDB locking |
| **Frontend** | React + Vite + Tailwind CSS |
| **Authentication** | Amazon Cognito (JWT via API Gateway authorizer) |
| **Hosting** | AWS Amplify (auto-deploy from GitHub) |
| **CI/CD** | GitHub Actions — Terraform plan on PR, apply via reviewer comment |

---

## Repository Structure

```
vantagepoint-data-product/
├── .github/
│   └── workflows/
│       └── terraform.yml              # CI/CD: plan on PR, apply via comment
├── terraform/
│   ├── main.tf                        # Provider config, Secrets Manager
│   ├── backend.tf                     # S3 remote state + DynamoDB lock
│   ├── warehouse.tf                   # Snowflake warehouse (XSMALL)
│   ├── database.tf                    # Database + schema
│   ├── roles.tf                       # RBAC roles + grants
│   ├── users.tf                       # Snowflake user assignments
│   ├── tables.tf                      # Accounts, opportunities, usage_logs, interaction_transcripts
│   ├── s3.tf                          # Data lake bucket
│   ├── networking.tf                  # VPC, private subnet, NAT Gateway, security group, route table
│   ├── glue.tf                        # Glue IAM role, connection, S3 scripts bucket, ETL job config
│   ├── lambda.tf                      # Transcript pipeline Lambdas + Step Functions state machine
│   ├── api_gateway.tf                 # HTTP API, Lambda integrations, Cognito JWT authorizer
│   ├── cognito.tf                     # User Pool, App Client, test user
│   └── amplify.tf                     # Amplify app, branch, build spec
├── data-generation/
│   ├── generate_accounts.py           # 200 synthetic accounts (random.seed for reproducibility)
│   ├── generate_opportunities.py      # ~350 opportunities across accounts
│   ├── generate_usage_logs.py         # 7,500 platform usage records (Hive-partitioned JSON)
│   ├── generate_transcripts.py        # 650 interaction transcripts (Hive-partitioned JSON)
│   └── sql/
│       ├── insert_accounts.sql        # Generated SQL INSERTs for Snowflake
│       └── insert_opportunities.sql   # Generated SQL INSERTs for Snowflake
├── pipelines/
│   ├── glue/
│   │   ├── ingest_usage_logs.py       # PySpark ETL: S3 JSON → Snowflake via Spark connector
│   │   └── jars/                      # Spark Snowflake connector + JDBC driver (gitignored)
│   └── lambda/
│       ├── layer/
│       │   └── Dockerfile             # Docker build for Snowflake connector Lambda Layer
│       ├── list_transcripts/          # Lists transcript files in S3
│       ├── process_transcripts/       # Bedrock sentiment + classification per transcript
│       ├── get_dashboard_data/        # GET /api/dashboard
│       ├── get_account_transcripts/   # GET /api/account/{id}/transcripts
│       └── rag_query/                 # POST /api/rag (recommendations + summaries)
├── dbt/
│   └── vantagepoint/
│       ├── dbt_project.yml
│       └── models/
│           ├── staging/               # stg_accounts, stg_opportunities, stg_usage_logs, stg_interaction_transcripts
│           │   ├── sources.yml        # Source definitions pointing to raw Snowflake tables
│           │   └── schema.yml         # 16 data quality tests (unique, not_null, accepted_values, relationships)
│           ├── intermediate/          # int_usage_metrics, int_transcript_metrics
│           └── marts/                 # account_health_score (incremental, merge on account_id)
├── frontend/
│   ├── src/
│   │   ├── App.jsx                    # Full SPA: login, dashboard, drill-down, AI features
│   │   ├── index.css                  # Tailwind imports
│   │   └── main.jsx                   # React entry point
│   ├── package.json
│   └── vite.config.js
└── .gitignore
```

**`.gitignore` includes:** `pipelines/glue/jars/`, `pipelines/lambda/layer/python/`, `pipelines/lambda/layer/snowflake-layer.zip`, `data-generation/usage_logs/`, `data-generation/transcripts/`, `frontend/node_modules/`, `frontend/dist/`, `frontend/.vite/`, `terraform/.terraform/`, `*.tfstate*`

---

## Prerequisites

| Requirement | Version / Notes |
|-------------|----------------|
| **AWS Account** | Access to S3, Lambda, Glue, Step Functions, API Gateway, Cognito, Amplify, Bedrock, Secrets Manager, VPC |
| **Snowflake Account** | Free trial works. Note your `account` identifier (e.g., `XVPQLZL-SZC19072`) |
| **Terraform** | >= 1.7.0 |
| **Docker** | Required for building the Lambda Layer (Snowflake connector has compiled C dependencies) |
| **Python** | >= 3.8 |
| **Node.js** | >= 18 |
| **dbt-core + dbt-snowflake** | `pip install dbt-core dbt-snowflake` |
| **AWS CLI** | Configured with credentials (`aws configure`) |
| **Git + GitHub** | Repository must be on GitHub for Amplify auto-deploy and CI/CD |

---

## Setup & Initialization

### Step 1: Clone the Repository

```bash
git clone https://github.com/VigneshSankar01/vantagepoint-data-product.git
cd vantagepoint-data-product
```

### Step 2: Store Credentials in AWS Secrets Manager

Secrets are created via CLI so that sensitive values never appear in Terraform state files.

```bash
# Snowflake credentials (used by Lambdas, Glue, and dbt)
aws secretsmanager create-secret \
  --name vantagepoint/snowflake/config \
  --secret-string '{"username":"YOUR_SNOWFLAKE_USER","password":"YOUR_SNOWFLAKE_PASS","account":"YOUR_SNOWFLAKE_ACCOUNT"}'

# GitHub personal access token (used by Amplify for repo access)
# Generate at: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
# Scope: repo (full control)
aws secretsmanager create-secret \
  --name vantagepoint/github/token \
  --secret-string "YOUR_GITHUB_PAT"
```

### Step 3: Build the Snowflake Connector Lambda Layer (Docker)

All Lambda functions that connect to Snowflake share a single Lambda Layer containing `snowflake-connector-python`. This must be built using Docker because the package includes compiled C binaries (`cryptography`) that must match Lambda's Amazon Linux 2 runtime — building on Windows or CloudShell produces incompatible binaries.

```bash
cd pipelines/lambda/layer

# Build inside Lambda's exact environment
docker build -t lambda-snowflake-layer .
docker create --name layer-extract lambda-snowflake-layer
docker cp layer-extract:/opt/python ./python
docker rm layer-extract

# Zip and upload to S3
# Linux/Mac:
zip -r snowflake-layer.zip python
# Windows PowerShell:
# Compress-Archive -Path python -DestinationPath snowflake-layer.zip

aws s3 cp snowflake-layer.zip s3://vantagepoint-glue-scripts/lambda/snowflake-layer.zip

# Clean up local build artifacts
rm -rf python snowflake-layer.zip
# Windows: Remove-Item -Recurse python; del snowflake-layer.zip
```

The `Dockerfile` used:

```dockerfile
FROM public.ecr.aws/lambda/python:3.11
RUN pip install snowflake-connector-python -t /opt/python
CMD ["echo", "done"]
```

The resulting Layer structure on Lambda:

```
/opt/python/
├── snowflake/
├── cryptography/
├── pyOpenSSL/
├── cffi/
└── ... (20+ dependencies)
```

### Step 4: Download Glue JARs (Spark Snowflake Connector)

AWS Glue does not ship with Snowflake connectors. Two JAR files must be downloaded from Maven Central and uploaded to S3 for the Glue ETL job.

```bash
cd pipelines/glue/jars

# Spark Snowflake Connector — translates Spark DataFrame operations into Snowflake COPY INTO commands
curl -O https://repo1.maven.org/maven2/net/snowflake/spark-snowflake_2.12/2.16.0-spark_3.3/spark-snowflake_2.12-2.16.0-spark_3.3.jar

# Snowflake JDBC Driver — the underlying network layer that connects to Snowflake's API
curl -O https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/3.17.0/snowflake-jdbc-3.17.0.jar

# Upload to S3 (referenced by Glue job via --extra-jars argument in Terraform)
aws s3 cp spark-snowflake_2.12-2.16.0-spark_3.3.jar s3://vantagepoint-glue-scripts/jars/
aws s3 cp snowflake-jdbc-3.17.0.jar s3://vantagepoint-glue-scripts/jars/
```

These JARs are in `.gitignore` — binary files don't belong in Git.

How the JARs work together at runtime:

```
Glue PySpark Script
  ↓ spark.write.format("net.snowflake.spark.snowflake")
Spark Snowflake Connector (spark-snowflake JAR)
  ↓ stages data as Parquet → runs COPY INTO
Snowflake JDBC Driver (snowflake-jdbc JAR)
  ↓ actual network connection
Snowflake
```

### Step 5: Deploy Infrastructure via Terraform

```bash
cd terraform
terraform init    # Downloads providers, initializes S3 backend
terraform plan    # Review what will be created
terraform apply   # Deploy everything — type 'yes' to confirm
```

This provisions the following resources:

**Snowflake:** Warehouse (`VANTAGEPOINT_WH`, XSMALL), database (`VANTAGEPOINT_PROD`), schema (`B2BSAAS`), RBAC roles (`VANTAGEPOINT_ADMIN` read/write, `VANTAGEPOINT_READ_ONLY` select-only), user assignments, and all four raw tables.

**AWS Networking:** Default VPC reference, a private subnet (`172.31.96.0/24`), a NAT Gateway with Elastic IP in the public subnet, a route table routing `0.0.0.0/0` from the private subnet through the NAT Gateway, and a security group allowing outbound HTTPS (443) + self-referencing for Glue worker communication. The NAT Gateway is required because Glue runs inside the private subnet but needs to reach Snowflake on the public internet.

**AWS Glue:** IAM role with S3 + Secrets Manager permissions, a network connection attached to the private subnet, the scripts S3 bucket (`vantagepoint-glue-scripts`), and the ETL job pointing to `ingest_usage_logs.py` with `--extra-jars` referencing both JAR files in S3.

**AWS Lambda + Step Functions:** The Snowflake connector Lambda Layer (from the S3 zip), two Lambda functions for the transcript pipeline (`list_transcripts` and `process_transcripts`), and a Step Functions state machine that orchestrates them — the Map state fans out to 24 parallel invocations (one per S3 file, MaxConcurrency 5) with retry/exponential backoff per file.

**AWS API Gateway:** HTTP API with three Lambda integrations (`GET /api/dashboard`, `GET /api/account/{id}/transcripts`, `POST /api/rag`), a Cognito JWT authorizer attached to all routes, and CORS configuration.

**Amazon Cognito:** User Pool, App Client (no client secret, for SPA), and a test user.

**AWS Amplify:** App connected to GitHub repo via the stored PAT, build spec configured for the `frontend/` subdirectory, `master` branch with auto-build enabled, and a custom rewrite rule (`/<*>` → `/index.html`) for SPA routing.

**Terraform state** is stored in S3 (`vantagepoint-terraform-state`) with DynamoDB locking (`vantagepoint-terraform-lock`).

### Step 6: Generate & Load Synthetic Data

The case study provided schemas, not data. All data is generated synthetically using Python scripts with `random.seed` for reproducibility.

```bash
cd data-generation

python generate_accounts.py         # → sql/insert_accounts.sql
python generate_opportunities.py    # → sql/insert_opportunities.sql
python generate_usage_logs.py       # → usage_logs/ (Hive-partitioned JSON)
python generate_transcripts.py      # → transcripts/ (Hive-partitioned JSON)
```

**CRM data → Snowflake directly via SQL:** Open a Snowflake worksheet and execute:

```sql
-- Run the contents of these files:
-- data-generation/sql/insert_accounts.sql      (200 INSERT statements)
-- data-generation/sql/insert_opportunities.sql  (~350 INSERT statements)
```

**Usage logs & transcripts → S3:** Upload the generated Hive-partitioned JSON to S3. The folder structure uses `year=/month=` partitioning which Glue reads natively.

```bash
aws s3 cp usage_logs/ s3://vantagepoint-data-lake/raw/usage_logs/ --recursive
aws s3 cp transcripts/ s3://vantagepoint-data-lake/raw/transcripts/ --recursive

# Delete local copies to avoid bloating the repo (folders are in .gitignore)
rm -rf usage_logs/ transcripts/
```

**Data specifications:**

| Table | Records | Key Characteristics |
|-------|---------|-------------------|
| **Accounts** | 200 | 25–30% churned, 9 industries, 2 tiers (Enterprise/Standard), ARR, subscription dates |
| **Opportunities** | ~350 | 1–3 deals per account, stages (prospecting/closed-won/closed-lost), deal values in GBP |
| **Usage Logs** | 7,500 | 12 platform features, ~62% error-free, 3 error codes (TIMEOUT/AUTH_FAIL/RATE_LIMIT), 1–5 users per account, spans 2023–2024 |
| **Transcripts** | 650 | 40% support tickets (account_id), 35% sales calls (opportunity_id), 25% emails (either), template-based complaint text |

### Step 7: Run Data Pipelines

**Pipeline 1 — AWS Glue (Usage Logs):**

Glue runs a PySpark job that reads all JSON from S3 using a DynamicFrame, converts to a DataFrame, renames columns to Snowflake's UPPERCASE convention, casts types, deduplicates on `session_id`, drops rows with null required fields, and writes to the `USAGE_LOGS` table. The Spark Snowflake connector stages data as Parquet files internally and runs `COPY INTO` — Snowflake's fastest ingestion method.

```bash
aws glue start-job-run --job-name vantagepoint-usage-logs-ingestion
```

The Glue job runs inside the VPC private subnet and reaches Snowflake via the NAT Gateway.

**Pipeline 2 — Step Functions + Lambda + Bedrock (Transcripts):**

Step Functions orchestrates the transcript pipeline. The first Lambda lists 24 transcript files from S3. A Map state fans out to the second Lambda — one invocation per file, max 5 concurrent. Each invocation reads the file, loops through ~27 transcripts, sends each to Bedrock Nova Micro for sentiment scoring (-1 to +1) and complaint classification (one of: billing, performance, bugs, feature_request, onboarding, security, data_quality, general), parses the JSON response, and writes enriched records to Snowflake. If Bedrock returns unparseable output, defaults to sentiment 0.0 and category "general" instead of failing. Retries with exponential backoff (10s, 2 max retries) per file — a single file failure doesn't lose progress on the other 23.

```bash
aws stepfunctions start-execution \
  --state-machine-arn arn:aws:states:us-east-1:YOUR_ACCOUNT_ID:stateMachine:vantagepoint-transcript-pipeline
```

### Step 8: Configure and Run dbt

**One-time setup — create `~/.dbt/profiles.yml`:**

```yaml
vantagepoint:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: YOUR_SNOWFLAKE_ACCOUNT    # e.g. XVPQLZL-SZC19072
      user: YOUR_SNOWFLAKE_USER
      password: YOUR_SNOWFLAKE_PASSWORD
      role: ACCOUNTADMIN
      database: VANTAGEPOINT_PROD
      warehouse: VANTAGEPOINT_WH
      schema: B2BSAAS
      threads: 4
```

**Verify the connection:**

```bash
cd dbt/vantagepoint
dbt debug    # Should show "Connection test: [OK]"
```

**Run transformations:**

```bash
dbt run      # Builds all 7 models
dbt test     # Runs 16 schema tests (unique, not_null, accepted_values, relationships)
```

**The 7 dbt models:**

| Layer | Model | What It Does |
|-------|-------|-------------|
| **Staging** | `stg_accounts` | Clean pass-through + deduplication via `QUALIFY ROW_NUMBER()` |
| **Staging** | `stg_opportunities` | Clean pass-through + deduplication |
| **Staging** | `stg_usage_logs` | Clean pass-through + deduplication |
| **Staging** | `stg_interaction_transcripts` | Clean pass-through + deduplication |
| **Intermediate** | `int_usage_metrics` | Aggregates 7,500 rows → 1 row per account (sessions, features_adopted, error_rate, days_since_last_active) |
| **Intermediate** | `int_transcript_metrics` | Aggregates 650 rows → 1 row per account (avg_sentiment, support_ticket_count, top_complaint_category via ROW_NUMBER with 3-level tie-breaking) |
| **Mart** | `account_health_score` | LEFT JOINs accounts + both intermediate tables, computes 0–100 score, COALESCE defaults for NULLs. Materialized as incremental with merge on account_id |

Staging deduplication makes the entire pipeline **idempotent** — safe to re-run Glue or Step Functions without creating duplicate rows downstream.

### Step 9: Verify the Frontend

**Locally (optional):**

```bash
cd frontend
npm install
npm run dev
# Opens at http://localhost:5173
```

**Via Amplify (production):** Amplify auto-deploys on push to `master`. If the first build hasn't triggered, start it manually:

```bash
aws amplify start-job --app-id YOUR_AMPLIFY_APP_ID --branch-name master --job-type RELEASE
```

The Amplify build spec (configured in Terraform) runs from the `frontend/` subdirectory:

```yaml
version: 1
applications:
  - frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: dist
        files:
          - '**/*'
    appRoot: frontend
```

### Step 10: Create Cognito Users

The platform is secured via Amazon Cognito. Users must be created by an administrator.

```bash
# Create user
aws cognito-idp admin-create-user \
  --user-pool-id us-east-1_KvDkfPdr3 \
  --username user@company.com \
  --user-attributes Name=email,Value=user@company.com \
  --temporary-password TempPass123! \
  --message-action SUPPRESS

# Set permanent password (bypasses forced change on first login)
aws cognito-idp admin-set-user-password \
  --user-pool-id us-east-1_KvDkfPdr3 \
  --username user@company.com \
  --password PermanentPassword123! \
  --permanent
```

Log in at the Amplify URL with these credentials. The JWT token is stored in React state and sent with every API call via the `Authorization` header. API Gateway validates the token via a Cognito JWT authorizer before any Lambda executes — the Lambdas themselves handle zero auth logic.

---

## Architecture Decisions

### Why Two Different Pipelines?

**Glue for usage logs:** 7,500 structured JSON records that need reading, cleaning, and bulk loading. Spark excels at parallel data processing. The Spark Snowflake connector stages data as Parquet and runs `COPY INTO` — Snowflake's fastest ingestion path.

**Step Functions + Lambda for transcripts:** Each transcript requires an individual HTTP call to Bedrock for sentiment and classification. Spark is not designed for sequential API calls — you'd loop row-by-row, defeating the purpose. Lambda with boto3 calls Bedrock natively. Step Functions adds orchestration: parallel fan-out, per-file retries, and fault isolation.

### Why Context Stuffing Instead of Full RAG?

Full RAG with Bedrock Knowledge Bases would require OpenSearch Serverless as the vector store — minimum 2 OCUs running at ~$0.98/hour (~$24/day, ~$70–94 for 3–4 days). With 200 accounts and 650 transcripts, the entire dataset fits in the context window. RAG's value is retrieving relevant chunks from data too large to fit — at this scale, context stuffing achieves the same result for pennies. The architecture is designed so upgrading to Knowledge Bases is a natural next step: the RAG Lambda already handles prompt construction and Bedrock calls — migration means adding a retrieval step before generation.

### Why Glue Needs a NAT Gateway

Glue runs inside a VPC private subnet for security. Snowflake is on the public internet. The NAT Gateway in the public subnet allows Glue to initiate outbound connections to Snowflake without being directly exposed to inbound internet traffic.

### Why Docker for the Lambda Layer

`snowflake-connector-python` depends on `cryptography`, which compiles C code against the system's GLIBC version. Building on Windows produces `.dll` files (incompatible with Lambda's Linux). Building on AWS CloudShell (Amazon Linux 2023, GLIBC 2.28) produces binaries incompatible with Lambda (Amazon Linux 2, GLIBC 2.26). Docker with Lambda's official base image (`public.ecr.aws/lambda/python:3.11`) guarantees exact binary compatibility.

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                             │
├──────────────┬──────────────────┬───────────────────────────────┤
│  CRM Data    │  Usage Logs      │  Interaction Transcripts      │
│  (SQL →      │  (S3 / Hive-     │  (S3 / Hive-partitioned       │
│   Snowflake) │   partitioned    │   JSON)                       │
│              │   JSON)          │                               │
└──────┬───────┴────────┬─────────┴──────────────┬────────────────┘
       │                │                        │
       │         ┌──────▼──────┐          ┌──────▼──────────┐
       │         │  AWS Glue   │          │ Step Functions  │
       │         │  PySpark    │          │  + Lambda       │
       │         │  + Spark SF │          │  + Bedrock      │
       │         │  Connector  │          │  (Sentiment +   │
       │         │  + JDBC     │          │  Classification)│
       │         └──────┬──────┘          └──────┬──────────┘
       │                │                        │
       │         [VPC Private Subnet]     [Outside VPC]
       │         [NAT Gateway → Internet]
       │                │                        │
┌──────▼────────────────▼────────────────────────▼────────────────┐
│                        SNOWFLAKE                                │
│  VANTAGEPOINT_PROD.B2BSAAS                                     │
│                                                                 │
│  Raw: ACCOUNTS | OPPORTUNITIES | USAGE_LOGS | INTERACTION_TRANS │
│                           │                                     │
│                    ┌──────▼──────┐                               │
│                    │  dbt Core   │                               │
│                    │  7 models   │                               │
│                    │  16 tests   │                               │
│                    └──────┬──────┘                               │
│                           │                                     │
│              ┌────────────▼────────────┐                        │
│              │  ACCOUNT_HEALTH_SCORE   │                        │
│              │  (Source of Truth)      │                        │
│              └────────────┬────────────┘                        │
└───────────────────────────┼─────────────────────────────────────┘
                            │
                 ┌──────────▼──────────┐
                 │  API Gateway (HTTP) │
                 │  + Cognito JWT Auth │
                 ├─────────────────────┤
                 │ GET  /dashboard     │──→ Lambda + Snowflake Layer
                 │ GET  /account/{id}/ │──→ Lambda + Snowflake Layer
                 │      transcripts    │
                 │ POST /rag           │──→ Lambda + Snowflake Layer + Bedrock
                 └──────────┬──────────┘
                            │
                 ┌──────────▼──────────┐
                 │   AWS Amplify       │
                 │   React + Vite +    │
                 │   Tailwind CSS      │
                 │   (auto-deploy from │
                 │    GitHub master)   │
                 └─────────────────────┘

         ┌──────────────────────────────────────┐
         │  CROSS-CUTTING                       │
         │  • Terraform (entire stack as IaC)   │
         │  • Secrets Manager (all credentials) │
         │  • GitHub Actions (plan/apply CI/CD) │
         │  • S3 + DynamoDB (Terraform state)   │
         └──────────────────────────────────────┘
```

---

## API Endpoints

**Base URL:** `https://6odxcq4waj.execute-api.us-east-1.amazonaws.com/api`

All endpoints require a valid Cognito JWT token in the `Authorization` header.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/dashboard` | Returns all 200 accounts with health scores and all signals |
| `GET` | `/api/account/{account_id}/transcripts` | Returns Bedrock-enriched transcript records for a specific account |
| `POST` | `/api/rag` | Accepts a prompt, returns AI-generated recommendation or transcript summary |

The three Lambdas share a single Snowflake Connector Lambda Layer. Credentials are fetched from Secrets Manager at runtime.

---

## Health Score Formula

The Account Health Score (0–100) is computed in the `account_health_score` dbt mart using six weighted signals:

| Signal | Weight | Source | Logic |
|--------|--------|--------|-------|
| Session count | 15 | `int_usage_metrics` | More sessions = healthier |
| Feature adoption | 15 | `int_usage_metrics` | More features used out of 12 = healthier |
| Error rate | 10 | `int_usage_metrics` | Lower error rate = healthier |
| Engagement recency | 20 | `int_usage_metrics` | Last active within 7 days = max score, 90+ days = 0 |
| Sentiment | 25 | `int_transcript_metrics` | Average sentiment from Bedrock (-1 to +1), normalized to 0–25 |
| Support burden | 15 | `int_transcript_metrics` | Fewer support tickets = healthier |

Sentiment and recency are weighted highest — sentiment turns negative before usage drops (leading indicator), and 90+ days inactive means the account is effectively gone regardless of what the CRM says.

**Risk Tiers (computed in frontend):** ≥65 = Healthy, 40–64 = At Risk, <40 = Critical, `is_churned = true` overrides everything as Churned.

---

## AI / Bedrock Integration

Amazon Bedrock (Nova Micro, temperature 0.1) is used in three distinct stages:

**1. Classification During Ingestion (Batch)** — The Step Functions pipeline sends each transcript to Bedrock with a structured prompt requesting JSON output: a sentiment score (-1 to +1) and a complaint category from a fixed list of 8. Results are stored permanently in Snowflake as part of the transcript record.

**2. Recommendations at Query Time (Real-time)** — When a user expands an account row, the frontend constructs a prompt containing that account's health score, sentiment, ticket count, days inactive, and complaint category. The RAG Lambda also fetches all 200 accounts from Snowflake as portfolio context. Bedrock generates a 2–3 sentence actionable recommendation.

**3. Transcript Summaries at Query Time (Real-time)** — After the frontend loads an account's raw transcripts, it packages all transcript bodies with metadata and sends them to the same RAG Lambda. Bedrock synthesizes the interaction history into themes, tone shifts, and trajectory.

The architecture is model-agnostic — swapping to Claude on Bedrock is a one-line config change on the model ID.

---

## CI/CD Pipeline

Infrastructure changes follow a GitOps workflow via **GitHub Actions**:

1. Developer creates a branch, modifies `terraform/` files, opens a Pull Request
2. GitHub Actions automatically runs `terraform plan` and posts the output as a PR comment
3. Reviewer inspects the plan
4. Reviewer comments `terraform apply` to approve
5. GitHub Actions runs `terraform apply` and posts the result

Only repository owners and collaborators can trigger `terraform apply`.

Terraform state is stored in **S3** (`vantagepoint-terraform-state`) with **DynamoDB locking** (`vantagepoint-terraform-lock`) to prevent concurrent modifications.

Frontend changes pushed to `master` are **automatically deployed** to Amplify.

---

## Data Integrity

Four layers of protection ensure data quality:

1. **Staging deduplication** — All 4 staging models use `QUALIFY ROW_NUMBER()` to catch duplicates from pipeline re-runs, making the entire system idempotent
2. **Bedrock error defaults** — If Bedrock returns unparseable output during transcript processing, defaults to sentiment 0.0 and category "general" instead of crashing the pipeline
3. **dbt schema tests** — 16 tests across all staging models: `unique`, `not_null`, `accepted_values`, and `relationships` (referential integrity)
4. **COALESCE defaults in the mart** — Accounts missing usage or transcript data receive low scores via defaults, never NULL scores

---

## Production Improvements

- **SNS/SQS Alerting** — Notifications on health score threshold breaches, Glue failures, Lambda error spikes
- **Bedrock Batch Inference** — Bulk processing instead of 650 individual API calls
- **Full RAG** — Bedrock Knowledge Bases + OpenSearch Serverless vector store for production-scale datasets
- **Tiered S3 Storage** — Lifecycle policies (Standard → Infrequent Access → Glacier)
- **Small Files Compaction** — Merge Hive-partitioned JSON or use Kinesis Firehose for pre-batched S3 delivery
- **EventBridge Orchestration** — Glue → Step Functions → `dbt run && dbt test` on a scheduled cron
- **Multi-Environment** — dev/staging/prod with separate Terraform state files and Snowflake databases
- **Custom DNS** — Route 53 instead of default Amplify URL
- **CORS Lockdown** — Restrict `allow_origins` to the Amplify domain only
- **Federated Auth** — Cognito SSO integration with Okta/Azure AD via SAML/OIDC
- **Self-Service Signup** — Cognito self-registration with email verification
- **WAF** — AWS WAF on Amplify for DDoS protection
- **Secrets Rotation** — Automatic Snowflake credential rotation via Secrets Manager

---

## License

This project was built as a case study submission for Sage.
