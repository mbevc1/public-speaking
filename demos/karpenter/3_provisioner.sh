#!/bin/bash

CLUSTER_NAME=mb
K8S_VERSION="1.30"
ARM_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-arm64/recommended/image_id --query Parameter.Value --output text)"
AMD_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2/recommended/image_id --query Parameter.Value --output text)"
GPU_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2-gpu/recommended/image_id --query Parameter.Value --output text)"

cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1
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
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      expireAfter: 720h # 30 * 24h = 720h - expire and recycle nodes daily
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
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 1m
    budgets:
    - nodes: "20%" # 10% default
    - nodes: "5"
    - nodes: "0"
      schedule: "@daily"
      duration: 10m
---
apiVersion: karpenter.k8s.aws/v1
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
  amiSelectorTerms:
    #- id: "${ARM_AMI_ID}"
    #- id: "${AMD_AMI_ID}"
    #- id: "${GPU_AMI_ID}" # <- GPU Optimized AMD AMI
    - name: "amazon-eks-node-${K8S_VERSION}-*" # <- automatically upgrade when a new AL2 EKS Optimized AMI is released. This is unsafe for production workloads. Validate AMIs in lower environments before deploying them to production.
  #launchTemplate: MyLaunchTemplate            # optional, see Launch Template documentation
  tags:
    managed_by: "karpenter"                    # optional, add tags for your own use
    #karpenter.sh/discovery: ${CLUSTER_NAME}   # needs to match the SG selector
    team: a-team
EOF

echo "---"
kubectl get nodepool default -o yaml | yq #-M
echo "---"
kubectl get ec2nodeclass default -o yaml | yq #-M
