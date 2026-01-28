#!/bin/bash

export CLUSTER_NAME=mb
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export K8S_VERSION="1.35"

# Spin up EKS cluster
#envsubst < eksctl.yaml
echo "Create K8s cluster..."
eksctl create cluster -f - <<EOF
$(envsubst < eksctl.yaml)
EOF

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
