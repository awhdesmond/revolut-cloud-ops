output "ecr_repo_url" {
  value       = aws_ecr_repository.revolut_user_service.repository_url
  description = "ECR repository URL"
}

output "rds_hostnames" {
  description = "RDS instance hostnames"
  value       = module.rds.rds_hostname
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.rds_port
}

output "rds_username" {
  description = "RDS instance username"
  value       = module.rds.rds_username
}