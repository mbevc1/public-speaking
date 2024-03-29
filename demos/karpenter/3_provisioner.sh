#!/bin/bash

CLUSTER_NAME=mb

cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    metadata:
      #annotations:
      #  custom-annotation: custom-value
      labels: # Added to provisioned nodes
        team: a-team
    spec:
      requirements: # using well-known annotations
        - key: "karpenter.k8s.aws/instance-category"
          operator: In
          values: ["c", "m", "t"] # t4g
        - key: "karpenter.k8s.aws/instance-cpu"
          operator: Lt
          values: ["33"]
          #  operator: In
          #  values: ["4", "8", "16", "32"]
          #- key: karpenter.k8s.aws/instance-hypervisor
          #  operator: In
          #  values: ["nitro"]
        - key: "node.kubernetes.io/instance-type"
          operator: In
          values: ["m5.xlarge", "m5.2xlarge", "m5.4xlarge", "m5.8xlarge", "m5.16xlarge", "c5.xlarge", "c5.2xlarge", "c5.4xlarge", "c5.9xlarge", "c5.18xlarge", "t4g.nano", "t4g.micro", "t4g.small", "t4g.xlarge", "t4g.2xlarge"]
        - key: "topology.kubernetes.io/zone"
          operator: In
          values: ["eu-west-1a", "eu-west-1c"]
        - key: "kubernetes.io/arch"
          operator: In
          values: ["arm64", "amd64"]
        - key: "karpenter.sh/capacity-type" # If not included, the webhook for the AWS cloud provider will default to on-demand, not spot
          operator: In
          values: ["on-demand"]
      nodeClassRef:
        name: default
  # These fields vary per cloud provider, see your cloud provider specific documentation
  #provider: {}
  limits:
    cpu: 1000
  #providerRef:                                # optional, recommended to use instead of 'provider'
  #  name: default
  #provider:
  #  subnetSelector:
  #    karpenter.sh/discovery: ${CLUSTER_NAME}
  #  securityGroupSelector:
  #    karpenter.sh/discovery: ${CLUSTER_NAME}
  #  tags:
  #    team: a-team
  #  instanceProfile: KarpenterNodeInstanceProfile-${CLUSTER_NAME}
  # Enables consolidation which attempts to reduce cluster cost by both removing un-needed nodes and down-sizing those
  # that can't be removed. Mutually exclusive with the ttlSecondsAfterEmpty parameter.
  #consolidation:
  #  enabled: true
  #ttlSecondsUntilExpired: 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;
  ##ttlSecondsAfterEmpty: 30
  #weight: 1 # similar to afinity weigth (higher is better)
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h # 30 * 24h = 720h - expire and recycle nodes daily
    budgets:
    - nodes: "20%" # 10% default
    - nodes: "5"
    - nodes: "0"
      schedule: "@daily"
      duration: 10m
---
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2 # Amazon Linux 2
  role: "KarpenterNodeRole-${CLUSTER_NAME}"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${CLUSTER_NAME}"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${CLUSTER_NAME}"
  #subnetSelector:
  #  karpenter.sh/discovery: ${CLUSTER_NAME}
  #securityGroupSelector:
  #  karpenter.sh/discovery: ${CLUSTER_NAME}
    #kubernetes.io/cluster/${CLUSTER_NAME}: '*'
  #instanceProfile: KarpenterNodeInstanceProfile-${CLUSTER_NAME}          # optional, if already set in controller args
  #launchTemplate: MyLaunchTemplate            # optional, see Launch Template documentation
  tags:
    managed_by: "karpenter"                    # optional, add tags for your own use
    #karpenter.sh/discovery: ${CLUSTER_NAME}   # needs to match the SG selector
    team: a-team
---
#apiVersion: karpenter.sh/v1alpha5
#kind: Provisioner
#metadata:
#  name: default2
#spec:
#  labels:
#    team: b-team
#  requirements:
#    - key: "karpenter.k8s.aws/instance-category"
#      operator: In
#      values: ["t", "c", "m"]
#    - key: "karpenter.k8s.aws/instance-cpu"
#      operator: In
#      values: ["2", "4", "8", "16", "32"]
#    - key: karpenter.k8s.aws/instance-hypervisor
#      operator: In
#      values: ["nitro"]
#    - key: karpenter.sh/capacity-type
#      operator: In
#      values: ["on-demand"]
#  limits:
#    resources:
#      cpu: 1000
#  providerRef:
#    name: default
#  weight: 1
#  ttlSecondsAfterEmpty: 10
EOF

echo "---"
kubectl get nodepool default -o yaml | yq #-M
echo "---"
kubectl get ec2nodeclass default -o yaml | yq #-M
