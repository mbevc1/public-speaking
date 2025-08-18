#!/usr/bin/env python3

import boto3
import datetime
import argparse
import matplotlib.pyplot as plt

def get_aws_costs(months=1):
    client = boto3.client('ce')  # AWS Cost Explorer client

    # Define the date range (default: last month)
    today = datetime.date.today()
    start_date = (today.replace(day=1) - datetime.timedelta(days=30 * months)).strftime('%Y-%m-%d')
    end_date = today.strftime('%Y-%m-%d')

    # Query AWS Cost Explorer excluding credits
    response = client.get_cost_and_usage(
        TimePeriod={
            'Start': start_date,
            'End': end_date
        },
        Granularity='MONTHLY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {'Type': 'DIMENSION', 'Key': 'SERVICE'}
        ],
        Filter={
            'Not': {
                'Dimensions': {
                    'Key': 'RECORD_TYPE',
                    'Values': ['Credit']
                }
            }
        }
    )

    # Process response data
    service_costs = {}
    for result in response['ResultsByTime']:
        for item in result['Groups']:
            service = item['Keys'][0]
            cost = float(item['Metrics']['UnblendedCost']['Amount'])
            service_costs[service] = service_costs.get(service, 0) + cost

    return service_costs

def plot_costs(service_costs, months):
    sorted_costs = sorted(service_costs.items(), key=lambda x: x[1], reverse=True)
    services, costs = zip(*sorted_costs) if sorted_costs else ([], [])
    total_spend = sum(costs)

    plt.figure(figsize=(12, max(6, len(services) * 0.5)))
    plt.barh(services, costs, color='skyblue')
    plt.xlabel("Cost (USD)")
    plt.ylabel("AWS Service")
    plt.title(f"AWS Accumulative Spend by Service (Last {months} Month{'s' if months > 1 else ''})\nTotal Spend: ${total_spend:.2f}", fontsize=14, fontweight='bold')
    plt.gca().invert_yaxis()  # Highest cost at the top

    for index, value in enumerate(costs):
        plt.text(value, index, f'${value:.2f}', va='center')

    plt.tight_layout()  # Ensure content fits properly
    plt.show()

def main():
    parser = argparse.ArgumentParser(description="Fetch AWS spending data for a specified number of months.")
    parser.add_argument("-m", "--months", type=int, default=1, help="Number of months to include in cost data (default: 1)")
    parser.add_argument("-s", "--spend", action="store_true", help="Only output the cumulative spend in console and skip the diagram")
    args = parser.parse_args()

    service_costs = get_aws_costs(args.months)
    total_spend = sum(service_costs.values())

    if not service_costs:
        print("No cost data available.")
    elif args.spend:
        print(f"Total AWS Spend for the last {args.months} month(s): ${total_spend:.2f}")
    else:
        plot_costs(service_costs, args.months)

if __name__ == "__main__":
    main()
