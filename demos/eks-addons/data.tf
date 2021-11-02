# Current region
data "aws_region" "current" {}

# Getting accountID
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
}

data "aws_ami" "bottlerocket_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-${var.k8s_version}-x86_64-*"]
  }
}

data "aws_iam_policy" "ssm" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
