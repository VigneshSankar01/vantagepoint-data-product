import random
import json
import os
from datetime import datetime, timedelta

random.seed(77)

num_records = 7500
num_accounts = 200

features = ["Dashboard", "Reports", "User Management", "Billing", 
            "API Console", "Integrations", "Notifications", "Data Export",
            "Workflow Builder", "Search", "Settings", "Audit Log"]

error_codes = [None, None, None, None, None,  # 5/8 chance of no error
               "ERR_TIMEOUT", "ERR_AUTH_FAIL", "ERR_RATE_LIMIT"]

records_by_month = {}

for i in range(1, num_records + 1):
    acc_num = random.randint(1, num_accounts)
    acc_id = f"ACC-{str(acc_num).zfill(4)}"
    user_id = f"USR-{acc_id}-{random.randint(1, 5)}"
    session_id = f"SES-{str(i).zfill(6)}"

    ts = datetime(2023, 1, 1) + timedelta(
        days=random.randint(0, 730),
        hours=random.randint(6, 22),
        minutes=random.randint(0, 59)
    )

    feature = random.choice(features)
    duration = random.randint(10, 3600)
    error = random.choice(error_codes)

    record = {
        "session_id": session_id,
        "account_id": acc_id,
        "user_id": user_id,
        "feature_used": feature,
        "session_duration_seconds": duration,
        "error_codes_encountered": error,
        "timestamp": ts.strftime("%Y-%m-%dT%H:%M:%SZ")
    }

    key = f"{ts.year}/{str(ts.month).zfill(2)}"
    if key not in records_by_month:
        records_by_month[key] = []
    records_by_month[key].append(record)

output_dir = "usage_logs"
for month_key, records in records_by_month.items():
    year, month = month_key.split("/")
    path = os.path.join(output_dir, f"year={year}", f"month={month}")
    os.makedirs(path, exist_ok=True)

    filepath = os.path.join(path, f"usage_logs_{year}_{month}.json")
    with open(filepath, "w") as f:
        for r in records:
            f.write(json.dumps(r) + "\n")

    print(f"  {filepath} -> {len(records)} records")

print(f"\nTotal: {num_records} records across {len(records_by_month)} monthly partitions")