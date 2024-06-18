resource "aws_prometheus_workspace" "main" {
  alias = "${var.name}"
}

data "aws_iam_policy_document" "prometheus" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.eks_oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.eks_namespace}:${var.eks_service_account}"]
    }

    principals {
      identifiers = [var.eks_oidc_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "prometheus" {
  name               = "prometheus"
  assume_role_policy = data.aws_iam_policy_document.prometheus.json
}

resource "aws_iam_policy" "prometheus_ingest_access" {
  name = "PrometheusDemoIngestAccess"

  policy = jsonencode({
    Statement = [{
      Action = [
        "aps:RemoteWrite"
      ]
      Effect   = "Allow"
      Resource = aws_prometheus_workspace.main.arn
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "prometheus_ingest_access" {
  role       = aws_iam_role.prometheus.name
  policy_arn = aws_iam_policy.prometheus_ingest_access.arn
}
