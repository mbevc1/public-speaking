#!/usr/bin/env python3

import boto3
import datetime
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

client = boto3.client("ce")

end_date = datetime.date.today().replace(day=1)
start_date = (end_date - datetime.timedelta(days=1)).replace(day=1)

response = client.get_cost_and_usage(
    TimePeriod={
        "Start": start_date.strftime("%Y-%m-%d"),
        "End": end_date.strftime("%Y-%m-%d"),
    },
    Granularity="DAILY",
    Metrics=["AmortizedCost"],
    Filter={"Not": {"Dimensions": {"Key": "RECORD_TYPE", "Values": ["Credit"]}}},
)

data = [
    {
        "Date": result["TimePeriod"]["Start"],
        "Cost": float(result["Total"]["AmortizedCost"]["Amount"]),
    }
    for result in response["ResultsByTime"]
]

df = pd.DataFrame(data)
df["Date"] = pd.to_datetime(df["Date"])

sns.set_theme(style="darkgrid")
plt.figure(figsize=(12, 6))
lineplot = sns.lineplot(
    data=df, x="Date", y="Cost", marker="o", linestyle="-", color="blue"
)
plt.title("Daily AWS Costs", fontsize=16)
plt.xlabel("Date", fontsize=14)
plt.ylabel("Cost ($)", fontsize=14)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
