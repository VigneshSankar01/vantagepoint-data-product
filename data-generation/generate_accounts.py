import random
from datetime import datetime, timedelta
#I took the help of AI to generate this code for me
random.seed(42)

industries = ["Technology", "Healthcare", "Finance", "Retail", "Manufacturing", 
              "Education", "Media", "Logistics", "Energy", "Real Estate"]
tiers = ["standard", "enterprise"]
owner_ids = [f"AO-{str(i).zfill(3)}" for i in range(1, 16)]

num_accounts = 200
churn_rate = 0.27

rows = []

for i in range(1, num_accounts + 1):
    acc_id = f"ACC-{str(i).zfill(4)}"
    industry = random.choice(industries)
    revenue = round(random.uniform(50000, 5000000), 2)
    tier = random.choices(tiers, weights=[0.6, 0.4])[0]
    owner = random.choice(owner_ids)

    start_date = datetime(2021, 1, 1) + timedelta(days=random.randint(0, 1200))
    is_churned = random.random() < churn_rate

    if is_churned:
        days_active = random.randint(60, 800)
        end_date = start_date + timedelta(days=days_active)
        if end_date > datetime.now():
            end_date = datetime.now() - timedelta(days=random.randint(1, 90))
        end_str = f"'{end_date.strftime('%Y-%m-%d')}'"
    else:
        end_str = "NULL"

    row = (f"('{acc_id}', '{industry}', {revenue}, '{start_date.strftime('%Y-%m-%d')}', "
           f"{end_str}, {str(is_churned).upper()}, '{tier}', '{owner}')")
    rows.append(row)

sql = "USE WAREHOUSE VANTAGEPOINT_WH;\n"
sql += "USE DATABASE VANTAGEPOINT_PROD;\n"
sql += "USE SCHEMA B2BSAAS;\n\n"
sql += "INSERT INTO ACCOUNTS (ACCOUNT_ID, INDUSTRY, ANNUAL_REVENUE, SUBSCRIPTION_START_DATE, "
sql += "SUBSCRIPTION_END_DATE, IS_CHURNED, TIER, ACCOUNT_OWNER_ID)\nVALUES\n"
sql += ",\n".join(rows) + ";"

with open("sql/insert_accounts.sql", "w") as f:
    f.write(sql)

print(f"Generated {num_accounts} account records -> sql/insert_accounts.sql")