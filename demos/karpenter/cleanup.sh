#!/bin/bash

CLUSTER_NAME=mb
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
INSTANCE_PROFILE=$(aws iam list-instance-profiles-for-role --role-name="KarpenterNodeRole-${CLUSTER_NAME}" --query "InstanceProfiles[*].InstanceProfileName" --output text)

helm uninstall karpenter --namespace karpenter
#eksctl delete iamserviceaccount --cluster ${CLUSTER_NAME} --name karpenter --namespace karpenter
#aws iam remove-role-from-instance-profile --role-name="KarpenterNodeRole-${CLUSTER_NAME}" --instance-profile-name="${INSTANCE_PROFILE}"
#aws iam delete-instance-profile --instance-profile-name="${INSTANCE_PROFILE}"
#aws iam delete-role --role-name="KarpenterNodeRole-${CLUSTER_NAME}"
eksctl delete cluster --name ${CLUSTER_NAME}
aws cloudformation delete-stack --stack-name Karpenter-${CLUSTER_NAME}
aws ec2 describe-launch-templates \
    | jq -r ".LaunchTemplates[].LaunchTemplateName" \
    | grep -i Karpenter-${CLUSTER_NAME} \
    | xargs -I{} aws ec2 delete-launch-template --launch-template-name {}
aws ec2 describe-network-interfaces \
    --filters Name=status,Values=available \
    | jq -r ".NetworkInterfaces[].NetworkInterfaceId" \
    | xargs -I{} aws ec2 delete-network-interface --network-interface-id {}
