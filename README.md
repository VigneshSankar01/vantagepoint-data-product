# VantagePoint Data Product

A strategic data product solution for VantagePoint, a B2B SaaS platform.
Unifies CRM, platform usage, and interaction transcript data to unlock commercial value.

## Project Structure

- `terraform/` — Infrastructure as Code (Snowflake, AWS, RBAC)
- `data-generation/` — Synthetic data generation scripts
- `pipelines/` — ETL pipelines (Glue + Lambda)
- `ai/` — Amazon Bedrock / LLM integration
- `frontend/` — React/Vite consumption layer
- `docs/` — Architecture docs and presentation

## Tech Stack

- **Storage & Compute:** Snowflake
- **Cloud Infrastructure:** AWS (S3, Lambda, Glue, Step Functions, Secrets Manager)
- **AI/ML:** Amazon Bedrock
- **IaC:** Terraform
- **Frontend:** React + Vite
