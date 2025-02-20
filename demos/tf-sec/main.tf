resource "random_pet" "pet" {}

locals {
  db-creds = {
    username = "foo"
    password = var.db-pass != null ? var.db-pass : random_pet.pet.id
  }
  creds   = jsondecode(aws_secretsmanager_secret_version.db-creds.secret_string)["password"]
  e-creds = jsondecode(ephemeral.aws_secretsmanager_secret_version.eph-db-creds.secret_string)["password"]
}

resource "aws_secretsmanager_secret" "db-creds" {
  name                    = "db-creds"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db-creds" {
  secret_id     = aws_secretsmanager_secret.db-creds.id
  secret_string = jsonencode(local.db-creds)
}

ephemeral "aws_secretsmanager_secret_version" "eph-db-creds" {
  secret_id = aws_secretsmanager_secret.db-creds.id

  depends_on = [aws_secretsmanager_secret_version.db-creds]
}

# Configure the MySQL provider
provider "mysql" {
  endpoint = aws_db_instance.db.endpoint
  username = aws_db_instance.db.username
  password = local.e-creds
}

# Create a Database
resource "mysql_database" "app" {
  name = "my_awesome_app"

  depends_on = [module.vpc, aws_db_instance.db]
}

resource "aws_ssm_parameter" "secret" {
  name             = "/test/password"
  description      = "The Password parameter"
  type             = "SecureString"
  value_wo         = local.e-creds
  value_wo_version = 1
}

resource "aws_db_instance" "db" {
  allocated_storage           = 10
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = false
  apply_immediately           = true
  storage_type                = "gp2"
  engine                      = "mariadb"
  engine_version              = "11.4"
  instance_class              = "db.t4g.micro"
  identifier                  = random_pet.pet.id
  db_name                     = "mydb"
  username                    = local.db-creds["username"]
  password                    = var.db-pass
  #password                    = local.creds
  #password                    = local.e-creds
  skip_final_snapshot = true
  storage_encrypted   = true
  publicly_accessible = true
  #manage_master_user_password = true
  #username                    = jsondecode(aws_secretsmanager_secret_version.db-creds.secret_string)["username"]

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name
}

#data "aws_secretsmanager_secret_version" "fetch" {
#  secret_id = aws_db_instance.db.master_user_secret[0].secret_arn
#}
