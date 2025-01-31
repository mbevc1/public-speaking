#!/bin/bash

export CLUSTER_NAME=mb
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export K8S_VERSION="1.32"
export KARPENTER_VERSION="1.2.1"

# Creates IAM resources used by Karpenter
#TEMPOUT=$(mktemp)
#TEMPOUT=iam-cfn.yaml
#curl -fsSL https://raw.githubusercontent.com/aws/karpenter-provider-aws/v"${KARPENTER_VERSION}"/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml > $TEMPOUT \ &&
TEMPOUT=cloudformation.yaml
echo "Creating IAM role..."
aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"

# Spin up EKS cluster
#envsubst < eksctl.yaml
echo "Create K8s cluster..."
eksctl create cluster -f - <<EOF
$(envsubst < eksctl.yaml)
EOF

## Add the karpenter node role to your aws-auth configmap, allowing nodes with this role to connect to the cluster.
#eksctl create iamidentitymapping \
#  --username system:node:{{EC2PrivateDNSName}} \
#  --cluster "${CLUSTER_NAME}" \
#  --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}" \
#  --group system:bootstrappers \
#  --group system:nodes
#
## Create an AWS IAM Role, Kubernetes service account, and associate them using IRSA. Permission to launch instances.
## Only creates the role and let's Helm chart to create SA
#eksctl create iamserviceaccount \
#  --cluster "${CLUSTER_NAME}" --name karpenter --namespace karpenter \
#  --role-name "${CLUSTER_NAME}-karpenter" \
#  --attach-policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}" \
#  --role-only \
#  --approve

# If using spot instances and only needed once!
#aws iam create-service-linked-role --aws-service-name spot.amazonaws.com || true
# If the role has already been successfully created, you will see:
# An error occurred (InvalidInput) when calling the CreateServiceLinkedRole operation: Service role name AWSServiceRoleForEC2Spot has been taken in this account, please try a different suffix.

# EBS CIS addon
#eksctl create iamserviceaccount \
#    --name ebs-csi-controller-sa \
#    --namespace kube-system \
#    --cluster ${CLUSTER_NAME} \
#    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
#    --override-existing-serviceaccounts \
#    --approve \
#    --role-only \
#    --role-name AmazonEKS_EBS_CSI_DriverRole
#
#SERVICE_ACCOUNT_ROLE_ARN=$(aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole | jq -r '.Role.Arn')
#
#eksctl create addon --name aws-ebs-csi-driver --cluster $CLUSTER_NAME \
#    --service-account-role-arn $SERVICE_ACCOUNT_ROLE_ARN --force
