variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "eks_name" {
  description = "EKS name"
  type        = string
  default     = "eks"
}

variable "k8s_version" {
  description = "EKS K8S version"
  type        = string
  default     = "1.30"
}

variable "cluster_addons" {
  description = "List of strings specifying cluster addons"
  type        = list(string)
  default     = ["vpc-cni", "kube-proxy", "coredns"]
}
