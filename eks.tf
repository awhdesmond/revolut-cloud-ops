locals {
  eks_version = "1.30"
}

# EKS will use this role to create resources on our behalf
resource "aws_iam_role" "eks_cluster" {
  name = "${var.eks_name}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = {
      Action = "sts.AssumeRole",
      Effect = "Allow",
      Sid    = "",
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }
  })
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  # ARN of the policy you want to apply
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

  # the role of the policy should apply to
  role = aws_iam_role.eks_cluster.name
}

# KMS Key

resource "aws_kms_key" "eks_encryption" {
  description         = "KMS key for EKS cluster encryption"
  policy              = data.aws_iam_policy_document.kms_key_policy.json
  enable_key_rotation = true
}


resource "aws_eks_cluster" "eks" {
  name     = var.eks_name
  version  = var.k8s_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true

    subnet_ids         = concat(module.vpc.private_subnets, module.vpc.public_subnets)
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy
  ]
}

// OIDC Provider

data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}


# Addons

data "aws_eks_addon_version" "main" {
  for_each = toset(var.cluster_addons)

  addon_name         = each.key
  kubernetes_version = aws_eks_cluster.main.version
}

resource "aws_eks_addon" "main" {
  for_each = toset(var.cluster_addons)

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = each.key
  addon_version               = data.aws_eks_addon_version.main[each.key].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on = [
    aws_eks_node_group.main
  ]
}

# AWS LBC IAM

resource "aws_iam_role" "aws_lbc" {
  name = "${aws_eks_cluster.eks.name}-aws-lbc"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = {
      Effect = "Allow",
      Action = "sts.AssumeRoleWithWebIdentity",
      Principals = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      },
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" : "sts.amazonaws.com",
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" : "system:serviceaccount:platform-aws:aws-load-balancer-controller"
        }
      }
    }
  })
}

resource "aws_iam_policy" "aws_lbc" {
  policy = file("./iam/AWSLoadBalancerController.json")
  name   = "AWSLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  policy_arn = aws_iam_policy.aws_lbc.arn
  role       = aws_iam_role.aws_lbc.name
}

# AWS SECRET MANAGEMENT IAM


