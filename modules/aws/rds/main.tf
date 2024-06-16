resource "aws_kms_key" "rds_kms_key" {
  deletion_window_in_days = 30

  tags = merge(var.default_tags, {
    Name = "RDS KMS key"
  })
}

resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-"
  vpc_id = var.vpc_id

  ingress {
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.db_security_group_ingress_cidr_blocks
  }
}

resource "aws_db_subnet_group" "users" {
  name       = var.db_name
  subnet_ids = [aws.subnet.private_1.id, aws.subnet.private_2.id]

  tags =  merge(default_tags, {
    Name = var.db_name
  })
}

resource "aws_db_parameter_group" "users" {
  name   = var.db_name
  family = var.db_family
}

resource "aws_db_instance" "users" {
  storage_type           = var.db_storage_type
  identifier             = var.db_name
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_storage
  engine                 = var.db_engine
  engine_version         = var.db_version
  username               = "postgres"

  db_subnet_group_name   = aws_db_subnet_group.users.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  parameter_group_name   = aws_db_parameter_group.users.name
  skip_final_snapshot    = false

  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds_kms_key.arn

  # Enable Multi-AZ deployment for high availability
  multi_az = true
}
