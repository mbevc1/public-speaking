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
    type: Recreate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      terminationGracePeriodSeconds: 0
      containers:
        - name: inflate
          image: public.ecr.aws/eks-distro/kubernetes/pause:3.5
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

# 1 3 7-delSmall 100
#kubectl scale deployment inflate --replicas 5
#kubectl logs -f -n karpenter $(kubectl get pods -n karpenter -l karpenter=controller -o name)
#kubectl get node -L "node.kubernetes.io/instance-type" -L "topology.kubernetes.io/zone" -L "kubernetes.io/arch"
#kubectl scale deployment inflate --replicas 0

# 1 3
## ARM64
#kubectl patch deployment inflate -p '{"spec": {"template": {"spec": {"nodeSelector": {"kubernetes.io/arch": "arm64"}}}}}'
