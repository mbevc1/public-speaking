#!/bin/bash

CLUSTER_NAME=mb

SUBNET_IDS=$(aws cloudformation describe-stacks \
    --stack-name eksctl-${CLUSTER_NAME}-cluster \
    --query 'Stacks[].Outputs[?OutputKey==`SubnetsPrivate`].OutputValue' \
    --output text)

echo "Subnets: ${SUBNET_IDS}"

aws ec2 create-tags \
    --resources $(echo ${SUBNET_IDS//,/ }) \
    --tags Key="kubernetes.io/cluster/${CLUSTER_NAME}",Value=

