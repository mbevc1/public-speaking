data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

locals {
  cluster_name = "eks1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.1"

  name                 = "vpc1"
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

resource "tls_private_key" "nodes" {
  algorithm = "RSA"
}

resource "aws_key_pair" "nodes" {
  key_name   = "bottlerocket-nodes"
  public_key = tls_private_key.nodes.public_key_openssh
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "coredns"
  addon_version     = "v1.8.3-eksbuild.1" # 1.8.3 | 1.8.4
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "kube-proxy"
  addon_version     = "v1.21.2-eksbuild.2"
  resolve_conflicts = "NONE" # OVERWRITE
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "vpc-cni"
  addon_version     = "v1.9.0-eksbuild.1" # 1.7.10 | 1.9.0
  resolve_conflicts = "OVERWRITE"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.1.0"

  cluster_name    = local.cluster_name
  cluster_version = var.k8s_version
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  write_kubeconfig                = true
  manage_aws_auth                 = true
  cluster_endpoint_private_access = true
  enable_irsa                     = true
  #cluster_log_retention_in_days   = var.eks_log_retention

  tags = {
    Environment = "test"
  }

  #fargate_profiles = {
  #  default = {
  #    name = "default"
  #    selectors = [
  #      {
  #        namespace = "kube-system"
  #        labels = {
  #          k8s-app = "kube-dns"
  #        }
  #      },
  #      {
  #        namespace = "default"
  #        # Kubernetes labels for selection
  #        # labels = {
  #        #   Environment = "test"
  #        # }
  #      }
  #    ]

  #    # using specific subnets instead of all the ones configured in eks
  #    # subnets = ["subnet-0ca3e3d1234a56c78"]

  #    tags = {
  #      Owner = "test"
  #    }
  #  }
  #}

  map_roles    = var.map_roles
  map_users    = var.map_users
  map_accounts = var.map_accounts

  worker_groups_launch_template = [
    {
      name = "bottlerocket-nodes"
      # passing bottlerocket ami id
      ami_id               = data.aws_ami.bottlerocket_ami.id
      instance_type        = "t3a.small"
      asg_desired_capacity = 3
      key_name             = aws_key_pair.nodes.key_name

      # Since we are using default VPC there is no NAT gateway so we need to
      # attach public ip to nodes so they can reach k8s API server
      # do not repeat this at home (i.e. production)
      #public_ip = true

      # This section overrides default userdata template to pass bottlerocket
      # specific user data
      userdata_template_file = "${path.module}/userdata.toml"
      # we are using this section to pass additional arguments for
      # userdata template rendering
      userdata_template_extra_args = {
        enable_admin_container   = var.enable_admin_container
        enable_control_container = var.enable_control_container
        aws_region               = var.region
      }
      # example of k8s/kubelet configuration via additional_userdata
      additional_userdata = <<EOT
[settings.kubernetes.node-labels]
ingress = "allowed"
EOT
    }
  ]
}

# SSM policy for bottlerocket control container access
# https://github.com/bottlerocket-os/bottlerocket/blob/develop/QUICKSTART-EKS.md#enabling-ssm
resource "aws_iam_policy_attachment" "ssm" {
  name       = "ssm"
  roles      = [module.eks.worker_iam_role_name]
  policy_arn = data.aws_iam_policy.ssm.arn
}
