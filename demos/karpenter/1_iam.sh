#!/bin/bash

CLUSTER_NAME=mb
AWS_ACCOUNT_ID=803761598153

# Creates IAM resources used by Karpenter
#TEMPOUT=$(mktemp)
TEMPOUT=iam-cfn.yaml
#curl -fsSL https://raw.githubusercontent.com/awslabs/karpenter/"${KARPENTER_VERSION}"/docs/aws/karpenter.cloudformation.yaml > $TEMPOUT \ &&
aws cloudformation deploy \
  --stack-name Karpenter-${CLUSTER_NAME} \
  --template-file ${TEMPOUT} \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ClusterName=${CLUSTER_NAME}

# Add the karpenter node role to your aws-auth configmap, allowing nodes with this role to connect to the cluster.
eksctl create iamidentitymapping \
  --username system:node:{{EC2PrivateDNSName}} \
  --cluster ${CLUSTER_NAME} \
  --arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME} \
  --group system:bootstrappers \
  --group system:nodes
