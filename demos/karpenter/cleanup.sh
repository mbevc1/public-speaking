#!/bin/bash

CLUSTER_NAME=mb

helm uninstall karpenter --namespace karpenter
eksctl delete iamserviceaccount --cluster ${CLUSTER_NAME} --name karpenter --namespace karpenter
aws cloudformation delete-stack --stack-name Karpenter-${CLUSTER_NAME}
aws ec2 describe-launch-templates \
    | jq -r ".LaunchTemplates[].LaunchTemplateName" \
    | grep -i Karpenter-${CLUSTER_NAME} \
    | xargs -I{} aws ec2 delete-launch-template --launch-template-name {}
aws ec2 describe-network-interfaces \
    --filters Name=status,Values=available \
    | jq -r ".NetworkInterfaces[].NetworkInterfaceId" \
    | xargs -I{} aws ec2 delete-network-interface --network-interface-id {}
eksctl delete cluster --name ${CLUSTER_NAME}
