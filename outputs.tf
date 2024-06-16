output "ecr_repo_url" {
  value = aws_ecr_repository.revolut_user_service.repository_url
  description = "ECR repository URL"
}
