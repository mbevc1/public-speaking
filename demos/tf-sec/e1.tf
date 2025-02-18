module "child" {
  source = "./child"

  test = local.e-creds
}

ephemeral "aws_secretsmanager_random_password" "pass" {}

resource "aws_ssm_parameter" "secret2" {
  name             = "/test/password2"
  description      = "The Password parameter"
  type             = "SecureString"
  value_wo         = ephemeral.aws_secretsmanager_random_password.pass.random_password
  #value_wo         = module.child.something
  value_wo_version = 1
}

#output "sm-example" {
#  value     = ephemeral.aws_secretsmanager_random_password.example
#  ephemeral = true
#}
