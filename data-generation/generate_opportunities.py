import random
from datetime import datetime, timedelta

random.seed(99)

num_accounts = 200
stages = ["prospecting", "closed-won", "closed-lost"]
product_codes = ["Vantage Core ERP", "Vantage HRM Suite", "Vantage Financials", 
                 "Vantage Project Ops", "Vantage Procurement"]
lead_sources = ["Organic", "Referral", "Outbound", "Partner", "Event", "Paid Ads"]

rows = []
opp_counter = 1

for acc_num in range(1, num_accounts + 1):
    acc_id = f"ACC-{str(acc_num).zfill(4)}"
    
    # some accounts have no opportunities at all
    num_opps = random.choices([0, 1, 2, 3], weights=[0.15, 0.45, 0.28, 0.12])[0]

    for _ in range(num_opps):
        opp_id = f"OPP-{str(opp_counter).zfill(5)}"
        product = random.choice(product_codes)
        stage = random.choices(stages, weights=[0.25, 0.45, 0.30])[0]
        amount = round(random.uniform(5000, 250000), 2)
        close_date = datetime(2021, 6, 1) + timedelta(days=random.randint(0, 1400))
        source = random.choice(lead_sources)

        row = (f"('{opp_id}', '{acc_id}', '{product}', '{stage}', "
               f"{amount}, '{close_date.strftime('%Y-%m-%d')}', '{source}')")
        rows.append(row)
        opp_counter += 1

sql = "USE WAREHOUSE VANTAGEPOINT_WH;\n"
sql += "USE DATABASE VANTAGEPOINT_PROD;\n"
sql += "USE SCHEMA B2BSAAS;\n\n"
sql += "INSERT INTO OPPORTUNITIES (OPPORTUNITY_ID, ACCOUNT_ID, PRODUCT_CODE, STAGE, "
sql += "AMOUNT_GBP, CLOSE_DATE, LEAD_SOURCE)\nVALUES\n"
sql += ",\n".join(rows) + ";"

with open("sql/insert_opportunities.sql", "w") as f:
    f.write(sql)

print(f"Generated {opp_counter - 1} opportunity records -> sql/insert_opportunities.sql")