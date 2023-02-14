#!/bin/bash

#CLUSTER_NAME=mb
#AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

#eksctl delete cluster --name ${CLUSTER_NAME}
#eksctl delete addon --cluster mb --name aws-ebs-csi-driver
#kubectl delete deployment -n kube-system ebs-csi-controller
eksctl delete cluster -f eksctl.yaml --disable-nodegroup-eviction
