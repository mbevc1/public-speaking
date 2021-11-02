#!/bin/bash

CLUSTER_NAME=mb

cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1alpha3
kind: Provisioner
metadata:
  name: default
spec:
  cluster:
    name: ${CLUSTER_NAME}
    endpoint: $(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output json)
  ttlSecondsAfterEmpty: 30
  zones: ["eu-west-1a", "eu-west-1c"]
  instanceTypes:
    - m5.xlarge
    - m5.2xlarge
    - m5.4xlarge
    - m5.8xlarge
    - m5.16xlarge
    - c5.xlarge
    - c5.2xlarge
    - c5.4xlarge
    - c5.9xlarge
    - c5.18xlarge
    - t4g.nano
    - t4g.micro
    - t4g.small
    - t4g.xlarge
EOF

kubectl get provisioner default -o yaml
