data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "^al2023-ami-2023.*-x86_64"
}

locals {
  ec2_enable = true

  instances = {
    web = {
      ami  = data.aws_ami.amazon_linux.id
      size = "t3.micro"
    }
    db = {
      ami  = data.aws_ami.amazon_linux.id
      size = "t3.small"
    }
  }
}

action "aws_ec2_stop_instance" "all" {
  for_each = local.ec2_enable ? local.instances : {}

  config {
    instance_id = aws_instance.servers[each.key].id
  }
}

resource "aws_instance" "servers" {
  for_each = local.ec2_enable ? local.instances : {}

  ami           = each.value.ami
  instance_type = each.value.size

  tags = {
    Name = each.key
  }

  lifecycle {
    action_trigger {
      events  = [after_create]
      actions = [action.aws_ec2_stop_instance.all[each.key]]
    }
  }

  depends_on = [aws_default_vpc.default]
}
