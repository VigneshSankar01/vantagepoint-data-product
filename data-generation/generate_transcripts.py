import random
import json
import os
from datetime import datetime, timedelta

random.seed(55)

num_accounts = 200
num_transcripts = 650

support_templates = [
    "Hi, we've been experiencing constant timeouts when trying to load the {feature} module. This has been going on for three days now and our team can't get any work done. We need this resolved urgently.",
    "Our billing shows a charge for {product} but we downgraded last month. Can someone look into this? We shouldn't be paying for a tier we're not using anymore.",
    "The {feature} page keeps throwing a 500 error every time we try to export data. We've tried different browsers and machines. Nothing works. This is really frustrating.",
    "We have about 40 users on our account and the {feature} has become incredibly slow since last week's update. Load times went from 2 seconds to over 15 seconds.",
    "I'm reaching out because our admin account got locked out after a password reset. We've followed the recovery steps but nothing is working. This is blocking our entire team.",
    "Just wanted to flag that the {feature} integration with our CRM stopped syncing two days ago. No error messages, it just silently stopped. We rely on this for daily operations.",
    "We noticed some data discrepancies in the {feature} reports. The numbers don't match what we see in our internal systems. Can someone help us figure out what's going on?",
    "The API rate limits are killing us. We're hitting the cap within the first hour of business every day. We need either higher limits or a better way to batch our requests.",
    "Our contract says we should have access to {product} but the feature is greyed out for all our users. We've been waiting a week for someone to enable it.",
    "We love the platform overall but the {feature} needs serious work. The UX is confusing, the filters don't save, and half the time the page just refreshes and loses our work.",
    "Multiple users on our team are reporting that saved configurations in {feature} are disappearing after logout. This has happened at least five times this week.",
    "We ran into an issue where {feature} is double-counting some of our entries. The totals are inflated and we can't trust the data for our monthly reviews.",
    "Hi team, our SSO integration broke after your last platform update. None of our users can log in through our identity provider. This is a critical issue for us.",
    "The {feature} export function only gives us CSV but we need JSON or at least Excel format. We've requested this multiple times. Is there any timeline for this?",
    "We're getting charged for inactive user seats. We deactivated 12 users last quarter but they still show as active in billing. Please correct this."
]

sales_templates = [
    "Thanks for joining the call. We walked through the {product} demo today. The client seemed very interested in the reporting capabilities but had concerns about the pricing at the enterprise tier. They asked for a custom quote.",
    "Good call with the prospect. They're currently using a competitor product and are unhappy with the lack of API access. I showed them our {product} integrations and they were impressed. Next step is a technical deep-dive with their engineering team.",
    "The client is evaluating {product} against two other vendors. Their main priority is ease of onboarding for a team of 200+ users. I emphasized our guided setup and dedicated CSM. They want a proposal by end of week.",
    "Tough call today. The prospect likes {product} but their budget got cut this quarter. They asked if we could do a phased rollout starting with just the core module. I'm going to put together a scaled-down package.",
    "Had a fantastic demo with their CTO. They were particularly excited about the {feature} and how it integrates with their existing stack. They want to move fast. Sending the contract tomorrow.",
    "Follow-up call after the trial period. The client said their team found {product} intuitive but felt the {feature} was lacking compared to what they currently have. They need more customization options before committing.",
    "Initial discovery call with a mid-market prospect. They have about 80 employees and are looking to replace spreadsheets with a proper system. {product} is a strong fit. Scheduling a full demo next week.",
    "The prospect raised concerns about data migration from their legacy system. I assured them we have a dedicated onboarding team. They also asked about {product} uptime SLAs. Sending our reliability documentation.",
    "Closing call with the client. They've agreed to a 2-year enterprise contract for {product}. Annual value is around 85K GBP. Great outcome. Will loop in implementation team.",
    "The prospect went dark for two weeks but came back today. They said internal approvals took longer than expected. They're now ready to proceed with {product} but want a 15 percent discount. Escalating to management."
]

email_templates = [
    "Hi team, just following up on our conversation last week about {product}. We've reviewed the proposal internally and have a few questions about the implementation timeline. Could we schedule a 30-minute call this week?",
    "Thank you for the demo yesterday. Our team was impressed with {feature} but we'd like to understand more about the security certifications. Can you share your SOC 2 report?",
    "We've been a customer for over a year now and wanted to share some feedback. The {feature} has been great for our workflow, but we think there's room for improvement in the reporting module.",
    "Hi, I'm writing to request an upgrade to our current {product} subscription. We've grown our team and the standard tier limits are no longer sufficient. What are the options?",
    "Just wanted to let you know that our team has been really happy with {product}. The onboarding was smooth and the support team has been responsive. Looking forward to the new features on the roadmap.",
    "We need to discuss our renewal. Frankly, we've had a rough experience this quarter with downtime and slow support response times. Before we commit to another year, we need assurances that these issues will be addressed.",
    "Could you provide documentation on your data retention policies? Our compliance team needs this before we can proceed with the {product} procurement.",
    "Our finance team flagged that the invoice for this quarter doesn't match the pricing we agreed on. Can someone review this and send a corrected invoice?"
]

features = ["Dashboard", "Reports", "User Management", "Billing",
            "API Console", "Integrations", "Workflow Builder", "Data Export"]
products = ["Vantage Core ERP", "Vantage HRM Suite", "Vantage Financials",
            "Vantage Project Ops", "Vantage Procurement"]

interaction_types = ["support_ticket", "sales_call", "email"]
type_weights = [0.40, 0.35, 0.25]

records_by_month = {}

for i in range(1, num_transcripts + 1):
    int_id = f"INT-{str(i).zfill(5)}"
    acc_num = random.randint(1, num_accounts)
    acc_id = f"ACC-{str(acc_num).zfill(4)}"
    int_type = random.choices(interaction_types, weights=type_weights)[0]

    ts = datetime(2023, 1, 1) + timedelta(
        days=random.randint(0, 730),
        hours=random.randint(8, 18),
        minutes=random.randint(0, 59)
    )

    feature = random.choice(features)
    product = random.choice(products)

    if int_type == "support_ticket":
        body = random.choice(support_templates).format(feature=feature, product=product)
        record = {
            "interaction_id": int_id,
            "account_id": acc_id,
            "timestamp": ts.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "interaction_type": int_type,
            "transcript_body": body
        }
    elif int_type == "sales_call":
        opp_id = f"OPP-{str(random.randint(1, 350)).zfill(5)}"
        body = random.choice(sales_templates).format(feature=feature, product=product)
        record = {
            "interaction_id": int_id,
            "opportunity_id": opp_id,
            "timestamp": ts.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "interaction_type": int_type,
            "transcript_body": body
        }
    else:
        body = random.choice(email_templates).format(feature=feature, product=product)
        if random.random() < 0.5:
            record = {
                "interaction_id": int_id,
                "account_id": acc_id,
                "timestamp": ts.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "interaction_type": int_type,
                "transcript_body": body
            }
        else:
            opp_id = f"OPP-{str(random.randint(1, 350)).zfill(5)}"
            record = {
                "interaction_id": int_id,
                "opportunity_id": opp_id,
                "timestamp": ts.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "interaction_type": int_type,
                "transcript_body": body
            }

    key = f"{ts.year}/{str(ts.month).zfill(2)}"
    if key not in records_by_month:
        records_by_month[key] = []
    records_by_month[key].append(record)

output_dir = "transcripts"
for month_key, records in records_by_month.items():
    year, month = month_key.split("/")
    path = os.path.join(output_dir, f"year={year}", f"month={month}")
    os.makedirs(path, exist_ok=True)

    filepath = os.path.join(path, f"transcripts_{year}_{month}.json")
    with open(filepath, "w") as f:
        for r in records:
            f.write(json.dumps(r) + "\n")

    print(f"  {filepath} -> {len(records)} records")

print(f"\nTotal: {num_transcripts} transcripts across {len(records_by_month)} monthly partitions")