#!/bin/bash

# set default SC
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

#public.ecr.aws/kubecost/cost-analyzer:2.2.5
VERSION="2.2.5"
helm upgrade -i kubecost \
oci://public.ecr.aws/kubecost/cost-analyzer --version $VERSION \
--namespace kubecost --create-namespace \
-f https://raw.githubusercontent.com/kubecost/cost-analyzer-helm-chart/v$VERSION/cost-analyzer/values-eks-cost-monitoring.yaml
#--set persistentVolume.storageClass=gp2 \
#--set prometheus.server.persistentVolume.storageClass=gp2
