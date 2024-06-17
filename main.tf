resource "aws_ecr_repository" "revolut_user_service" {
  name                 = "revolut-user-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "vpc" {
  source = "./modules/aws/vpc"

  vpc_name                       = "main"
  cidr_block                     = "10.0.0.0/16"
  public_subnet_count            = 2
  public_subnet_additional_bits  = 2
  private_subnet_count           = 2
  private_subnet_additional_bits = 2

  default_tags = { env = "prod" }
}

module "rds" {
  source = "./modules/aws/rds"

  vpc_id                                = module.vpc.vpc_id
  db_name                               = "users"
  db_engine                             = "postgres"
  db_version                            = "16.2"
  db_family                             = "postgres16"
  db_instance_class                     = "db.t3.medium"
  db_subnets_id                         = module.vpc.private_subnets
  db_storage                            = 50
  db_security_group_ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  default_tags = { env = "prod" }
}

module "elasticache" {
  source = "./modules/aws/elasticache"

  vpc_id                                     = module.vpc.vpc_id
  cluster_name                               = "users"
  cluster_subnets_id                         = module.vpc.private_subnets
  cluster_security_group_ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks

  default_tags = { env = "prod" }
}

module "eks" {
  source = "./modules/aws/eks"
  vpc_id = module.vpc.vpc_id
  eks_name = "eks"
  eks_version = "1.30"
  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids = module.vpc.public_subnets
  default_tags = { env = "prod" }
}


