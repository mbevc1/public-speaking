resource "random_pet" "pet" {
}

locals {
  db-creds = {
    username = "foo"
    password = var.db-pass != null ? var.db-pass : random_pet.pet.id
  }
}

resource "aws_secretsmanager_secret" "db-creds" {
  name                    = "db-creds"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db-creds" {
  secret_id     = aws_secretsmanager_secret.db-creds.id
  secret_string = jsonencode(local.db-creds)
}

resource "aws_db_instance" "db" {
  allocated_storage           = 10
  allow_major_version_upgrade = true
  apply_immediately           = true
  storage_type                = "gp2"
  engine                      = "mariadb"
  engine_version              = "10.5"
  instance_class              = "db.t2.micro"
  name                        = "mydb"
  #username                    = jsondecode(aws_secretsmanager_secret_version.db-creds.secret_string)["username"]
  password                    = jsondecode(aws_secretsmanager_secret_version.db-creds.secret_string)["password"]
  username                    = "foo"
  #password                    = var.db-pass
  #password                    = "foobarbaz"
  skip_final_snapshot         = true
}
