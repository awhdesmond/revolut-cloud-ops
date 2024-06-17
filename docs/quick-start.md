# Quick Start

0. Install `aws` CLI by following the instructions [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and create an AWS account for `terraform` with `AdministratorAccess` permission.

1. Provision all the cloud resources
```bash
aws configure --profile terraform

terraform init
terraform apply

# Configure kube context
aws eks update-kubeconfig --region eu-west-1 --name eks --profile terraform
```

2. Store the values of the following terraform output:
   * `aws_lbc_role_arn`
   * `ecr_repo_url`
   * `elasticache_cluster_configuration_endpoint`
   * `elasticache_cluster_password_secret_name`
   * `rds_password_secret_arn`
   * `rds_password_secret_name`
   * `revolut_user_service_role_arn`


3. Clone `revolut-user-service`, run the following commands to build and push docker image:
```bash
export IMAGE_TAG=`git describe --dirty --always`
export CONTAINER_REGISTRY=<ecr_repo_url from terraform (without the repo)>
export CONTAINER_REPOSITORY=revolut-user-service
make docker
make docker-push
```

4. Clone [`revolut-gitops-k8s`](https://github.com/awhdesmond/revolut-gitops-k8s) repository.

5. In `revolut-gitops-k8s`, run the following commands to deploy platform components:
```bash
# Use the output from terraform: aws_lbc_role_arn
export AWS_LBC_ROLE_ARN=<aws_lbc_role_arn from terraform output>

sed -i '' \
    -e "s|eks.amazonaws.com\/role-arn:.*|eks.amazonaws.com/role-arn: ${AWS_LBC_ROLE_ARN}|g" \
    kustomize/platform/components/aws-lbc/base/templates/serviceaccount.yaml

make platform KUBE_CONTEXT=<EKS_KUBECTL_CONTEXT> ENV=prod
```

> `aws-lbc` also requires the EKS cluster name. In this example, we are using `eks`.


6. In `revolut-gitops-k8s`, run the following commands to deploy application components:
```bash
export USER_SERVICE_ROLE_ARN=arn:aws:iam::974860574511:role/eks-revolut-user-service-role

pushd kustomize/apps/components/user-service/api/prod
sed -i '' \
    -e "s|eks.amazonaws.com\/role-arn:.*|eks.amazonaws.com/role-arn: ${USER_SERVICE_ROLE_ARN}|g" \
    sa.yaml

kustomize edit set image revolut-user-service=${CONTAINER_REGISTRY}/${CONTAINER_REPOSITORY}:${IMAGE_TAG}
popd

make user-service KUBE_CONTEXT=<EKS_KUBECTL_CONTEXT> ENV=<ENV>
```