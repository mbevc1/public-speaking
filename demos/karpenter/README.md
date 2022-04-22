# Karpenter
This repository consists code examples for **Karpenter Cluster Autoscaler**.

![](https://github.com/aws/karpenter/blob/main/website/static/full_logo.png)

**Karpenter** is an Open Source Cluster Autoscaler tool developed and published by **AWS**.

## Folder Structure
```
├── README.md
├── manifests
│   ├── amd64-deployment.yaml
│   ├── amd64-provisioner.yaml
│   ├── arm64-deployment.yaml
│   ├── arm64-provisioner.yaml
│   ├── spot-deployment.yaml
│   └── spot-provisioner.yaml
└── terraform
    ├── eks.tf
    ├── iam.tf
    ├── karpenter.tf
    ├── outputs.tf
    ├── provider.tf
    ├── sg.tf
    ├── vars.tf
    └── vpc.tf
```
In the [Terraform folder](https://github.com/mbevc1/public-speaking/tree/main/demos/karpenter/terraform), you can find the necessary configuration files for deploying a **VPC**, an **EKS Cluster** and **Karpenter Helm Chart** on top of that EKS cluster. Terraform configurations also creates the **IAM** Roles and Instance Profiles. You can change the configurations according to your needs.

In the [Karpenter folder](https://github.com/mbevc1/public-speaking/tree/main/demos/karpenter/manifests), you can find the **Provisioner** and **Kubernetes Deployment** yaml files.

## Usage `eksctl`

* Create cluster using
```bash
eksctl create cluster -f eksctl.yaml
```
* Set up IAM roles/permissions, set up controllers, provisioners and deployment:
```bash
./1_iam.sh
./2_controllers.sh
./3_provisioner.sh
./4_deployment.sh
```
* Finally you can scale the deployments using ``kubectl scale deployment <deployment-name> --replicas=10``
* Clean-up:
```bash
./cleanup.sh
eksctl delete cluster -f eksctl.yaml
```

## Usage TF

- First, create the environment with Terraform.
```bash
terraform init
```
```bash
terraform plan
```
```bash
terraform apply
```
- Then you need to create the Provisioners and Deployments.
- Finally you can scale the deployments using ``kubectl scale deployment <deployment-name> --replicas=10``
- You can set the log level of the Karpenter to **DEBUG** to see more information using ``kubectl patch configmap config-logging -n karpenter --patch '{"data":{"loglevel.controller":"debug"}}``
- You can see the logs of the Karpenter Controller using ``kubectl logs -f -n karpenter $(kubectl get pods -n karpenter -l karpenter=controller -o name)``

## Cleanup

- First, you can delete the Deployments with ``kubectl delete deployment <deployment-name>``
- You can delete the Karpenter installation with ``helm uninstall karpenter -n karpenter``
- Finally, you can delete the whole environment with

```bash
terraform destroy
```
> PS: Do not forget to delete Launch Templates created by Karpenter from your AWS Account.
