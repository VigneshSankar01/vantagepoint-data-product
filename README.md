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
| **Data Warehouse** | Snowflake |
| **Cloud Infrastructure** | AWS (S3, Lambda, Glue, Step Functions, API Gateway, Secrets Manager) |
| **AI/ML** | Amazon Bedrock (Nova Micro) — sentiment classification, recommendations, summarization |
| **Transformations** | dbt (staging → intermediate → marts) |
| **Infrastructure as Code** | Terraform with S3 remote backend |
| **Frontend** | React + Vite + Tailwind CSS |
| **Authentication** | Amazon Cognito (JWT) |
| **Hosting** | AWS Amplify (auto-deploy from GitHub) |
| **CI/CD** | GitHub Actions — Terraform plan on PR, apply via comment |

---

## Repository Structure

```
vantagepoint-data-product/
├── .github/
│   └── workflows/
│       └── terraform.yml          # CI/CD: plan on PR, apply via comment
├── terraform/
│   ├── main.tf                    # Provider config, Secrets Manager
│   ├── backend.tf                 # S3 remote state backend
│   ├── warehouse.tf               # Snowflake warehouse
│   ├── database.tf                # Database + schema
│   ├── roles.tf                   # RBAC roles + grants
│   ├── users.tf                   # Snowflake user assignments
│   ├── tables.tf                  # Accounts, opportunities, usage logs, transcripts
│   ├── s3.tf                      # Data lake bucket
│   ├── networking.tf              # VPC, subnets, NAT Gateway (for Glue)
│   ├── lambda.tf                  # Transcript pipeline Lambdas + Step Functions
│   ├── api_gateway.tf             # API Gateway, Lambda integrations, Cognito authorizer
│   ├── cognito.tf                 # User Pool, App Client, test user
│   └── amplify.tf                 # Amplify hosting from GitHub
├── data-generation/
│   ├── generate_accounts.py       # 200 synthetic accounts
│   ├── generate_opportunities.py  # Opportunities per account
│   ├── generate_usage_logs.py     # 7,500 platform usage records
│   ├── generate_transcripts.py    # 650 interaction transcripts
│   └── sql/
│       ├── insert_accounts.sql
│       └── insert_opportunities.sql
├── pipelines/
│   ├── glue/                      # Usage logs: S3 → Snowflake
│   └── lambda/
│       ├── list_transcripts/      # Lists transcript files in S3
│       ├── process_transcripts/   # Bedrock sentiment + classification
│       ├── get_dashboard_data/    # Dashboard API endpoint
│       ├── get_account_transcripts/ # Account transcripts API endpoint
│       └── rag_query/             # AI recommendations + summaries
├── dbt/
│   └── vantagepoint/
│       ├── dbt_project.yml
│       └── models/
│           ├── staging/           # stg_accounts, stg_opportunities, stg_usage_logs, stg_interaction_transcripts
│           ├── intermediate/      # int_usage_metrics, int_transcript_metrics
│           └── marts/             # account_health_score (final source of truth)
├── frontend/
│   ├── src/
│   │   ├── App.jsx                # Full application: login, dashboard, drill-down, AI features
│   │   ├── index.css              # Tailwind imports
│   │   └── main.jsx               # React entry point
│   ├── package.json
│   └── vite.config.js
└── docs/
    └── architecture/              # Architecture diagrams and presentation
```

---

## Prerequisites

- **AWS Account** with access to S3, Lambda, Glue, Step Functions, API Gateway, Cognito, Amplify, Bedrock, Secrets Manager
- **Snowflake Account** (free trial works)
- **Terraform** >= 1.7.0
- **Node.js** >= 18
- **Python** >= 3.8
- **dbt-core** + **dbt-snowflake**
- **AWS CLI** configured with appropriate credentials
- **Git** + **GitHub** account

---

## Setup & Initialization

### 1. Clone the Repository

```bash
git clone https://github.com/VigneshSankar01/vantagepoint-data-product.git
cd vantagepoint-data-product
```

### 2. Store Credentials in AWS Secrets Manager

```bash
# Snowflake credentials
aws secretsmanager create-secret \
  --name vantagepoint/snowflake/config \
  --secret-string '{"username":"YOUR_USER","password":"YOUR_PASS","account":"YOUR_ACCOUNT"}'

# GitHub token (for Amplify)
aws secretsmanager create-secret \
  --name vantagepoint/github/token \
  --secret-string "YOUR_GITHUB_PAT"
```

### 3. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

This provisions: Snowflake warehouse/database/schema/RBAC, S3 data lake, VPC + NAT Gateway, Glue job, Lambda functions, Step Functions pipeline, API Gateway with Cognito authorizer, Cognito User Pool, and Amplify hosting.

### 4. Generate & Load Synthetic Data

```bash
cd ../data-generation
python generate_accounts.py
python generate_opportunities.py
python generate_usage_logs.py
python generate_transcripts.py
```

Run the generated SQL files in Snowflake. Upload usage logs and transcripts to S3:

```bash
aws s3 cp usage_logs/ s3://vantagepoint-data-lake/raw/usage_logs/ --recursive
aws s3 cp transcripts/ s3://vantagepoint-data-lake/raw/transcripts/ --recursive
```

### 5. Run Data Pipelines

```bash
# Ingest usage logs via Glue
aws glue start-job-run --job-name vantagepoint-usage-logs-ingestion

# Process transcripts via Step Functions (Bedrock sentiment + classification)
aws stepfunctions start-execution \
  --state-machine-arn arn:aws:states:us-east-1:YOUR_ACCOUNT:stateMachine:vantagepoint-transcript-pipeline
```

### 6. Run dbt Transformations

```bash
cd ../dbt/vantagepoint
dbt run
```

This builds 7 models: 4 staging, 2 intermediate (usage metrics + transcript metrics), and 1 mart (account_health_score).

### 7. Start Frontend Locally (Optional)

```bash
cd ../../frontend
npm install
npm run dev
```

Open `http://localhost:5173` — or use the live Amplify deployment.

---

## Authentication

The platform is secured with **Amazon Cognito**. Access is managed by an administrator.

**To request access:**
1. Contact the platform admin
2. Admin creates a user in Cognito via CLI or Terraform
3. Admin opens a PR with the new user configuration
4. After CI/CD approval, the user receives their credentials
5. User logs in at the Amplify URL with their email and password

**Admin command to add a new user:**

```bash
aws cognito-idp admin-create-user \
  --user-pool-id us-east-1_KvDkfPdr3 \
  --username newuser@company.com \
  --user-attributes Name=email,Value=newuser@company.com \
  --temporary-password TempPass123 \
  --message-action SUPPRESS

aws cognito-idp admin-set-user-password \
  --user-pool-id us-east-1_KvDkfPdr3 \
  --username newuser@company.com \
  --password PermanentPassword123 \
  --permanent
```

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                             │
├──────────────┬──────────────────┬───────────────────────────────┤
│  CRM Data    │  Usage Logs      │  Interaction Transcripts      │
│  (Snowflake) │  (S3 / JSON)     │  (S3 / Text)                  │
└──────┬───────┴────────┬─────────┴──────────────┬────────────────┘
       │                │                        │
       │         ┌──────▼──────┐          ┌──────▼──────────┐
       │         │  AWS Glue   │          │ Step Functions  │
       │         │  (ETL Job)  │          │ + Lambda        │
       │         └──────┬──────┘          │ + Bedrock       │
       │                │                 │ (Sentiment +    │
       │                │                 │  Classification)│
       │                │                 └──────┬──────────┘
       │                │                        │
┌──────▼────────────────▼────────────────────────▼────────────────┐
│                        SNOWFLAKE                                │
│  Raw Tables: accounts, opportunities, usage_logs, transcripts   │
│                           │                                     │
│                    ┌──────▼──────┐                               │
│                    │     dbt     │                               │
│                    │  7 models   │                               │
│                    └──────┬──────┘                               │
│                           │                                     │
│              ┌────────────▼────────────┐                        │
│              │  ACCOUNT_HEALTH_SCORE   │                        │
│              │  (Final Source of Truth) │                        │
│              └────────────┬────────────┘                        │
└───────────────────────────┼─────────────────────────────────────┘
                            │
                 ┌──────────▼──────────┐
                 │  API Gateway        │
                 │  + Cognito Auth     │
                 │  (JWT Authorizer)   │
                 ├─────────────────────┤
                 │ GET  /api/dashboard │
                 │ GET  /api/account/  │
                 │      {id}/transcripts│
                 │ POST /api/rag       │
                 └──────────┬──────────┘
                            │
                 ┌──────────▼──────────┐
                 │   AWS Amplify       │
                 │   React + Vite      │
                 └─────────────────────┘
```

---

## API Endpoints

**Base URL:** `https://6odxcq4waj.execute-api.us-east-1.amazonaws.com/api`

All endpoints require a valid JWT token in the `Authorization` header.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/dashboard` | Returns all 200 accounts with health scores and signals |
| `GET` | `/api/account/{account_id}/transcripts` | Returns enriched transcript records for a specific account |
| `POST` | `/api/rag` | Accepts a natural language query, returns AI-generated insight |

---

## Health Score Formula

The Account Health Score (0–100) is computed in dbt using these weighted signals:

| Signal | Weight | Logic |
|--------|--------|-------|
| Session count | 15% | More sessions = healthier |
| Feature adoption | 15% | More features used out of 12 = healthier |
| Error rate | 10% | Lower error rate = healthier |
| Engagement recency | 20% | Last active within 7 days = max score, 90+ days = 0 |
| Sentiment | 25% | Average sentiment from Bedrock analysis (-1 to +1) |
| Support burden | 15% | Fewer support tickets = healthier |

**Risk Tiers:** 65+ = Healthy, 40–64 = At Risk, <40 = Critical, Churned = already gone

---

## AI / Bedrock Integration

Amazon Bedrock (Nova Micro) is used in three places:

1. **Transcript Pipeline (Batch)** — Step Functions sends each transcript to Bedrock for sentiment scoring (-1 to +1) and complaint classification (bugs, billing, performance, data_quality, etc.)

2. **AI-Assisted Recommendations (Real-time)** — When a user expands an account, the frontend calls the RAG endpoint with that account's metrics. Bedrock generates a 2–3 sentence actionable recommendation.

3. **AI Transcript Summaries (Real-time)** — The actual transcript body text is sent to Bedrock to produce a narrative summary of the customer's interaction history, themes, and trajectory.

---

## CI/CD Pipeline

Infrastructure changes follow a GitOps workflow via **GitHub Actions**:

1. **Developer** creates a branch, modifies files in `terraform/`, and opens a Pull Request
2. **GitHub Actions** automatically runs `terraform plan` and posts the output as a PR comment
3. **Reviewer** inspects the plan output on the PR
4. **Reviewer** comments `terraform apply` to approve and execute the changes
5. **GitHub Actions** runs `terraform apply` and posts the result

Security: Only repository **owners** and **collaborators** can trigger `terraform apply`.

State is stored in an **S3 remote backend** (`vantagepoint-terraform-state`) with **DynamoDB locking** (`vantagepoint-terraform-lock`) to prevent concurrent modifications.

Frontend changes pushed to `master` are **automatically deployed** to Amplify via auto-build.

---

## Production Improvements

- **Custom Domain** — Configure via Amplify + Route 53 (e.g., `intelligence.vantagepoint.com`)
- **CORS Lockdown** — Restrict `allow_origins` to the Amplify domain only
- **Federated Auth** — Integrate Cognito with corporate SSO (Okta, Azure AD) via SAML/OIDC
- **Self-Service Signup** — Enable Cognito self-registration with email verification
- **Incremental dbt Models** — Switch account_health_score to incremental materialization for large-scale data
- **Monitoring** — CloudWatch alarms on Lambda errors, API Gateway 4xx/5xx rates, Glue job failures
- **Data Quality** — dbt tests for schema validation, null checks, and referential integrity
- **Caching** — API Gateway response caching to reduce Lambda cold starts
- **WAF** — Enable AWS WAF on Amplify for DDoS protection
- **Secrets Rotation** — Automatic rotation for Snowflake credentials via Secrets Manager

---

## License

This project was built as a case study submission for Sage.
