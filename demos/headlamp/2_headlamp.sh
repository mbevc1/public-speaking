#!/bin/bash

CLUSTER_NAME=mb
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
HEADLAMP_VERSION="0.39.0"

# ALB Ingress Class
kubectl apply -f alb-ingressclass.yaml

#helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
#helm repo add kubescape https://kubescape.github.io/helm-charts/
#helm repo update
#helm upgrade --install headlamp headlamp/headlamp --namespace kube-system --version ${HEADLAMP_VERSION} \
helm upgrade --install headlamp headlamp/headlamp --namespace kube-system \
    -f values.yaml
#  --set settings.clusterName=${CLUSTER_NAME} \

# Ingress
#kubectl apply -f headlamp-ing.yaml

# Get auth token
# kubectl create token headlamp --namespace kube-system
# Logs
# kubectl logs -f -n kube-system -l app.kubernetes.io/name=headlamp -c headlamp-plugin
#
# helm upgrade --install kubescape kubescape/kubescape-operator -n kubescape --create-namespace --set clusterName=`kubectl config current-context` --set capabilities.continuousScan=enable
