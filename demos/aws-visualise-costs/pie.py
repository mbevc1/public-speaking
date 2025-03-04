#!/usr/bin/env python3

import boto3
import datetime
import matplotlib.pyplot as plt
import seaborn as sns

client = boto3.client("ce")

end_date = datetime.date.today().replace(day=1)
start_date = (end_date - datetime.timedelta(days=1)).replace(day=1)

response = client.get_cost_and_usage(
    TimePeriod={
        "Start": start_date.strftime("%Y-%m-%d"),
        "End": end_date.strftime("%Y-%m-%d"),
    },
    Granularity="MONTHLY",
    Metrics=["AmortizedCost"],
    GroupBy=[{"Type": "DIMENSION", "Key": "SERVICE"}],
    Filter={
        "Not": {
            "Dimensions": {
                "Key": "RECORD_TYPE",
                "Values": ["Credit"],
            }
        }
    },
)

services_to_costs = {
    item["Keys"][0]: float(item["Metrics"]["AmortizedCost"]["Amount"])
    for item in response["ResultsByTime"][0]["Groups"]
}

total_cost = sum(services_to_costs.values())

services = [
    service
    for service in services_to_costs
    # Services that cost less than 2% of the total cost will be aggregated later
    if services_to_costs[service] / total_cost > 0.02
]
other_services = set(services_to_costs) - set(services)

costs = [services_to_costs[service] for service in services]

if other_services:
    services.append("Other")
    costs.append(sum(services_to_costs[service] for service in other_services))

plt.pie(costs, labels=services, colors=sns.color_palette("pastel"), autopct="%.0f%%")
plt.show()
