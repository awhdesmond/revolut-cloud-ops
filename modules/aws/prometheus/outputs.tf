output "prometheus_endpoint" {
  value = aws_prometheus_workspace.main.prometheus_endpoint
  description = "Managed Prometheus endpoint"
}

output "prometheus_role_arn" {
  value = aws_iam_role.prometheus.arn
  description = "Prometheus role arn"
}