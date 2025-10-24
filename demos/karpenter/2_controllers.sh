#!/bin/bash

CLUSTER_NAME=mb
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
#CLUSTER_ENDPOINT="$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output text)"
KARPENTER_IAM_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"
KARPENTER_VERSION="1.8.2"

#helm repo add karpenter https://awslabs.github.io/karpenter/charts
#helm repo add karpenter https://charts.karpenter.sh
#helm repo update
#helm upgrade --install karpenter karpenter/karpenter \
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version ${KARPENTER_VERSION} \
  --create-namespace --namespace karpenter \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${KARPENTER_IAM_ROLE_ARN} \
  --set settings.clusterName=${CLUSTER_NAME} \
  --set settings.defaultInstanceProfile=KarpenterNodeInstanceProfile-${CLUSTER_NAME} \
  --set settings.interruptionQueueName=${CLUSTER_NAME}
  #--set controller.image.repository=cgr.dev/chainguard/karpenter \
  #--set controller.image.digest=sha256:8d94dce2917501afabe9aa3323145e6ccc017478eab386fac460659ec5d6913e
  #--wait # for the defaulting webhook to install before creating a Provisioner
  # either "ip-name" or "resource-name"
  #--set settings.aws.nodeNameConvention=resource-name \
  #--set controller.resources.requests.cpu=1 \
  #--set controller.resources.requests.memory=1Gi \
  #--set controller.resources.limits.cpu=1 \
  #--set controller.resources.limits.memory=1Gi \
  #--set settings.aws.clusterEndpoint=${CLUSTER_ENDPOINT} \
  #--set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter" \
  #--set serviceAccount.create=false \
  #--set serviceAccount.name=karpenter \
# --version 0.5.5

# Metrics server
#kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Optional monitoring
#helm repo add grafana-charts https://grafana.github.io/helm-charts
#helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
#helm repo update

#kubectl create namespace monitoring

#curl -fsSL https://karpenter.sh/"${KARPENTER_VERSION}"/getting-started/getting-started-with-eksctl/prometheus-values.yaml | tee prometheus-values.yaml
#helm install --namespace monitoring prometheus prometheus-community/prometheus --values prometheus-values.yaml

#curl -fsSL https://karpenter.sh/"${KARPENTER_VERSION}"/getting-started/getting-started-with-eksctl/grafana-values.yaml | tee grafana-values.yaml
#helm install --namespace monitoring grafana grafana-charts/grafana --values grafana-values.yaml

# kubectl port-forward --namespace monitoring svc/grafana 3000:80
# kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode
