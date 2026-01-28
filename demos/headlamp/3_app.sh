#!/bin/bash

CLUSTER_NAME=mb
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

# ALB Ingress Class
kubectl apply -f alb-ingressclass.yaml

# Ingress
kubectl apply -f app-2048_full.yaml

# external-secrets
helm install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace
  # --set installCRDs=false
