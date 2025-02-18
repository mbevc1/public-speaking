#resource "aws_rds_cluster_instance" "db_instances" {
#  count               = 1
#  identifier          = "aurora-cluster-demo-${count.index}"
#  cluster_identifier  = aws_rds_cluster.db.id
#  instance_class      = "db.t4g.medium"
#  engine              = aws_rds_cluster.db.engine
#  engine_version      = aws_rds_cluster.db.engine_version
#  publicly_accessible = true
#}
#
#resource "aws_rds_cluster" "db" {
#  cluster_identifier          = "aurora-cluster-demo"
#  engine                      = "aurora-postgresql"
#  database_name               = "mydb"
#  master_username             = "foo"
#  manage_master_user_password = true
#  skip_final_snapshot         = true
#  storage_encrypted           = true
#  #master_password            = "must_be_eight_characters"
#
#  db_subnet_group_name   = module.vpc.database_subnet_group_name
#  vpc_security_group_ids = [aws_security_group.db.id]
#}
