#!/bin/bash

CLUSTER_NAME=mb

#  cluster:
#    name: ${CLUSTER_NAME}
#    endpoint: $(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output json)
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  labels: # Added to provisioned nodes
    team: a-team
  requirements: # using well-known annotations
    - key: "node.kubernetes.io/instance-type"
      operator: In
      values: ["m5.xlarge", "m5.2xlarge", "m5.4xlarge", "m5.8xlarge", "m5.16xlarge", "c5.xlarge", "c5.2xlarge", "c5.4xlarge", "c5.9xlarge", "c5.18xlarge", "t4g.nano", "t4g.micro", "t4g.small", "t4g.xlarge"]
    - key: "topology.kubernetes.io/zone"
      operator: In
      values: ["eu-west-1a", "eu-west-1c"]
    - key: "kubernetes.io/arch"
      operator: In
      values: ["arm64", "amd64"]
    - key: "karpenter.sh/capacity-type" # If not included, the webhook for the AWS cloud provider will default to on-demand, not spot
      operator: In
      values: ["on-demand"]
  # These fields vary per cloud provider, see your cloud provider specific documentation
  #provider: {}
  limits:
    resources:
      cpu: 1000
  providerRef:                                # optional, recommended to use instead of 'provider'
    name: default
  #provider:
  #  subnetSelector:
  #    karpenter.sh/discovery: ${CLUSTER_NAME}
  #  securityGroupSelector:
  #    karpenter.sh/discovery: ${CLUSTER_NAME}
  #  tags:
  #    team: a-team
  #  instanceProfile: KarpenterNodeInstanceProfile-${CLUSTER_NAME}
  # Enables consolidation which attempts to reduce cluster cost by both removing un-needed nodes and down-sizing those
  # that can't be removed.  Mutually exclusive with the ttlSecondsAfterEmpty parameter.
  consolidation:
    enabled: true
  ttlSecondsUntilExpired: 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;
  #ttlSecondsAfterEmpty: 30
---
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodeTemplate
metadata:
  name: default
spec:
  subnetSelector:
    karpenter.sh/discovery: ${CLUSTER_NAME}
  securityGroupSelector:
    #karpenter.sh/discovery: ${CLUSTER_NAME}
    kubernetes.io/cluster/${CLUSTER_NAME}: '*'
  instanceProfile: KarpenterNodeInstanceProfile-${CLUSTER_NAME}          # optional, if already set in controller args
  #launchTemplate: MyLaunchTemplate            # optional, see Launch Template documentation
  tags:
    managed_by: "karpenter"                    # optional, add tags for your own use
    #karpenter.sh/discovery: ${CLUSTER_NAME}   # needs to match the SG selector
    team: a-team
EOF

echo "---"
kubectl get provisioner default -o yaml
echo "---"
kubectl get awsnodetemplate default -o yaml
