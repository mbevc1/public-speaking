#!/bin/bash

# TFC_AWS_PROVIDER_AUTH=true
# TFC_AWS_RUN_ROLE_ARN=<arn>
aws cloudformation deploy --stack-name TFC-tf-actions --template-file cloudformation/tfc-role.yaml --no-fail-on-empty-changeset --capabilities CAPABILITY_NAMED_IAM
