#!/bin/bash

helm repo add karpenter https://awslabs.github.io/karpenter/charts
helm repo update
helm upgrade --install karpenter karpenter/karpenter \
  --namespace karpenter --set serviceAccount.create=false
# --version 0.3.2
