resource "aws_default_vpc" "default" {
  #force_destroy = true

  tags = {
    Name = "default"
  }
}
