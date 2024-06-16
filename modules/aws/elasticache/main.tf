
resource "aws_elasticache_subnet_group" "main" {
  name       = var.cluster_name
  subnet_ids = var.cluster_subnets_id

  tags =  merge(default_tags, {
    Name = var.cluster_name
  })
}

resource "aws_security_group" "main" {
  name_prefix = "elasticache-${var.cluster_name}-"
  vpc_id = var.vpc_id

  ingress {
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.cluster_security_group_ingress_cidr_blocks
  }
}

resource "aws_elasticache_cluster" "main" {

  cluster_id           = var.cluster_name
  node_type            = var.cluster_instance_class
  num_cache_nodes      = var.num_cache_nodes
  engine_version       = var.cluster_version
  parameter_group_name = var.cluster_parameter_group_name

  engine            = "redis"
  port              = 6379
  subnet_group_name = aws_elasticache_subnet_group.main.name

  transit_encryption_enabled = true
  security_group_ids         = [aws_security_group.main.id]
  apply_immediately = true
}
