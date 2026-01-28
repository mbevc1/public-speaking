#!/bin/bash

CLUSTER_NAME=mb
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

echo -n "Cleaning up Headlamp, apps and cluster..."
echo
kubectl delete deployment inflate
kubectl delete -f app-2048_full.yaml
kubectl delete -f headlamp-ing.yaml
helm uninstall headlamp --namespace kube-system
eksctl delete cluster --name ${CLUSTER_NAME}
echo "Done!"
