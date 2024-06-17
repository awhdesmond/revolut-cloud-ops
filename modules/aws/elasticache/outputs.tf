output "cluster_enabled" {
  description = "Whether cluster mode is neabled"
  value       = aws_elasticache_replication_group.main.cluster_enabled
  sensitive   = true
}
