output "rds_hostname" {
  description = "RDS instance hostnames"
  value       = [for instance in [aws_db_instance.main, aws_db_instance.replica]: instance.address]
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.main.username
}
