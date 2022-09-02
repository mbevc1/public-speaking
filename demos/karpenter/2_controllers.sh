#!/bin/bash

CLUSTER_NAME=mb
AWS_ACCOUNT_ID=764407762618

#helm repo add karpenter https://awslabs.github.io/karpenter/charts
helm repo add karpenter https://charts.karpenter.sh
helm repo update
helm upgrade --install karpenter karpenter/karpenter \
  --create-namespace --namespace karpenter --set serviceAccount.create=false \
  --set serviceAccount.name=karpenter \
  --set clusterName=${CLUSTER_NAME} \
  --set clusterEndpoint=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output json) \
  --set aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${CLUSTER_NAME}
  #--set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter" \
  #--wait
# --version 0.5.5
