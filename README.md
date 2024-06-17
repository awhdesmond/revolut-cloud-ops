# Revolut Cloud Ops

IaC repository for terraform configuration cloud resources.

## Getting Started
```bash
aws configure --profile terraform

terraform init
terraform apply

# Configure kube context
aws eks update-kubeconfig --region eu-west-1 --name eks --profile terraform
```

> Install `aws` CLI by following the instructions [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and create an AWS account for `terraform`.
