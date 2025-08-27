aws eks update-kubeconfig --region us-east-1 --name $(cd infra/terraform/envs/dev terraform output -raw cluster_name)

$env:AWS_REGION  = "us-east-1";$env:AWS_PROFILE = "dev" ;aws sts get-caller-identity

cd infra/terraform/envs/dev
aws eks update-kubeconfig --region us-east-1 --name "$(terraform output -raw cluster_name)"


kubectl get nodes -o wide
kubectl get ns