#!/bin/bash

CLUSTER_NAME=mb
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
#KARPENTER_VERSION="v0.27.0"

# Creates IAM resources used by Karpenter
#TEMPOUT=$(mktemp)
#TEMPOUT=iam-cfn.yaml
#curl -fsSL https://raw.githubusercontent.com/awslabs/karpenter/"${KARPENTER_VERSION}"/docs/aws/karpenter.cloudformation.yaml > $TEMPOUT \ &&
#curl -fsSL https://karpenter.sh/${KARPENTER_VERSION}/getting-started/getting-started-with-eksctl/cloudformation.yaml > cloudformation.yaml
TEMPOUT=cloudformation.yaml
aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"

# Add the karpenter node role to your aws-auth configmap, allowing nodes with this role to connect to the cluster.
eksctl create iamidentitymapping \
  --username system:node:{{EC2PrivateDNSName}} \
  --cluster "${CLUSTER_NAME}" \
  --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}" \
  --group system:bootstrappers \
  --group system:nodes

# Create an AWS IAM Role, Kubernetes service account, and associate them using IRSA. Permission to launch instances.
# Only creates the role and let's Helm chart to create SA
eksctl create iamserviceaccount \
  --cluster "${CLUSTER_NAME}" --name karpenter --namespace karpenter \
  --role-name "${CLUSTER_NAME}-karpenter" \
  --attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}" \
  --role-only \
  --approve

# If using spot instances and only needed once!
#aws iam create-service-linked-role --aws-service-name spot.amazonaws.com || true
# If the role has already been successfully created, you will see:
# An error occurred (InvalidInput) when calling the CreateServiceLinkedRole operation: Service role name AWSServiceRoleForEC2Spot has been taken in this account, please try a different suffix.
