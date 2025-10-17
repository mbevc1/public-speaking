#!/bin/bash

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  strategy:
    #type: Recreate
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  template:
    metadata:
      #annotations:
      #  karpenter.sh/do-not-disrupt: "true"
      labels:
        app: inflate
    spec:
      terminationGracePeriodSeconds: 0
      containers:
        - name: inflate
          image: public.ecr.aws/eks-distro/kubernetes/pause:3.10
          resources:
            requests:
              cpu: 1
      topologySpreadConstraints:
      #- labelSelector:
      #    matchLabels:
      #      app: inflate
      #  maxSkew: 2
      #  topologyKey: kubernetes.io/hostname
      #  whenUnsatisfiable: DoNotSchedule
      #- labelSelector:
      #    matchLabels:
      #      app: inflate
      #  maxSkew: 5
      #  topologyKey: topology.kubernetes.io/zone
      #  whenUnsatisfiable: ScheduleAnyway
      nodeSelector:
        kubernetes.io/arch: amd64
EOF

echo "Done!"
#read
sleep 2

echo "---"
kubectl get deployment inflate -o yaml | yq #-M

# 1 3 7-delSmall 100
#kubectl scale deployment inflate --replicas 5
#kubectl logs -f -n karpenter $(kubectl get pods -n karpenter -l karpenter=controller -o name)
#kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter --tail=100 | jq -M | grep -E "^|message|reason"
#kubectl get node -L "node.kubernetes.io/instance-type" -L "topology.kubernetes.io/zone" -L "kubernetes.io/arch" -L "karpenter.sh/capacity-type"
#eks-node-viewer --node-selector karpenter.sh/nodepool --extra-labels topology.kubernetes.io/zone --resources cpu,memory
#kubectl scale deployment inflate --replicas 0

# 1 3
## ARM64
#kubectl patch deployment inflate -p '{"spec": {"template": {"spec": {"nodeSelector": {"kubernetes.io/arch": "arm64"}}}}}'
