#!/bin/bash

CLUSTER_NAME=mb
AWS_ACCOUNT_ID=764407762618
KARPENTER_IAM_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"
KARPENTER_VERSION="v0.18.1"

#helm repo add karpenter https://awslabs.github.io/karpenter/charts
#helm repo add karpenter https://charts.karpenter.sh
#helm repo update
#helm upgrade --install karpenter karpenter/karpenter \
helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version ${KARPENTER_VERSION} \
  --create-namespace --namespace karpenter \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${KARPENTER_IAM_ROLE_ARN} \
  --set clusterName=${CLUSTER_NAME} \
  --set clusterEndpoint=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output json) \
  --set aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${CLUSTER_NAME}
  #--wait # for the defaulting webhook to install before creating a Provisioner
  #--set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter" \
  #--set serviceAccount.create=false \
  #--set serviceAccount.name=karpenter \
# --version 0.5.5

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
