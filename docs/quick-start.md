# Quick Start

## 0. Pre-requisites

1. Install `aws` CLI by following the instructions [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. Create an AWS account for `terraform` with `AdministratorAccess` permission.

## 1. Provision AWS Cloud resources

```bash
aws configure --profile terraform

terraform init
terraform apply

# Configure kube context
aws eks update-kubeconfig --region eu-west-1 --name eks --profile terraform
export EKS_KUBECTL_CONTEXT=`kubectl config current-context`
```

Store the values of the following terraform output:
   * `aws_lbc_role_arn`
   * `ecr_repo_url`
   * `elasticache_cluster_configuration_endpoint`
   * `elasticache_cluster_password_secret_name`
   * `rds_password_secret_arn`
   * `rds_password_secret_name`
   * `revolut_user_service_role_arn`
   * `prometheus_endpoint`
   * `prometheus_role_arn`

```bash
export IMAGE_TAG="0.1.0"
export CONTAINER_REPOSITORY=revolut-user-service
export CONTAINER_REGISTRY=<ecr_repo_url from terraform (without the repo)>
export AWS_LBC_ROLE_ARN=<aws_lbc_role_arn from terraform output>
export PROMETHEUS_ROLE_ARN=<prometheus_role_arn from terraform output>
export PROMETHEUS_ENDPOINT=<prometheus_endpoint from terraform output>
export USER_SERVICE_ROLE_ARN=<revolut_user_service_role_arn from terraform>
export RDS_HOST=<first rds_hostnames from terraform>
export REDIS_URI=<elasticache_cluster_configuration_endpoint from terraform>
```

## 2. Build Revolut User Service

Clone `revolut-user-service`, run the following commands to build and push docker image:

```bash
make docker
make docker-push
```

## 3. Deploy EKS Platform Components

Clone [`revolut-gitops-k8s`](https://github.com/awhdesmond/revolut-gitops-k8s) repository.

In `revolut-gitops-k8s`, run the following commands to deploy platform components:

```bash
./scripts/update-aws-fields-platform.sh
make platform KUBE_CONTEXT=${EKS_KUBECTL_CONTEXT}
```

> `aws-lbc` also requires the EKS cluster name. In this example, we are using `eks`.


## 4. Deploy Revolut User Service

In `revolut-gitops-k8s`, run the following commands to deploy application components:

```bash
./scripts/update-aws-fields-user-service.sh
make user-service KUBE_CONTEXT=${EKS_KUBECTL_CONTEXT}
```

## 5. Perform Queries

```bash
export NGINX_NLB_HOSTNAME=`kubectl -n platform-ingress get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'`

for i in {1..1000}; do
   curl -XPUT -d '{"dateOfBirth": "2021-10-01"}' "http://${NGINX_NLB_HOSTNAME}/hello/apple" -w '%{http_code}\n'
   curl -XGET "http://${NGINX_NLB_HOSTNAME}/hello/apple"
done
```