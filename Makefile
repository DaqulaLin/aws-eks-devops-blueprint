AWS_REGION ?= us-east-1
ENV ?= dev

init:
	cd infra/terraform/envs/$(ENV) && terraform init


initupgrade:
	cd infra/terraform/envs/$(ENV) && terraform init -upgrade

initreconfigure:
	cd infra/terraform/envs/$(ENV) && terraform init -reconfigure

fmt:
	cd infra/terraform/envs/$(ENV) && terraform fmt -recursive

validate:
	cd infra/terraform/envs/$(ENV) && terraform validate

plan:
	cd infra/terraform/envs/$(ENV) && terraform plan -var="aws_region=$(AWS_REGION)"

apply:
	cd infra/terraform/envs/$(ENV) && terraform apply -auto-approve -var="aws_region=$(AWS_REGION)"

destroy:
	cd infra/terraform/envs/$(ENV) && terraform destroy -auto-approve -var="aws_region=$(AWS_REGION)"

list:
	cd infra/terraform/envs/$(ENV) && terraform state list

output:
	cd infra/terraform/envs/$(ENV) && terraform output

clustername:
	cd infra/terraform/envs/$(ENV) && terraform output -raw cluster_name

refresh:
	cd infra/terraform/envs/$(ENV) && terraform apply -refresh-only -var="aws_region=$(AWS_REGION)"



kubeconfig:
	cd infra/terraform/envs/$(ENV) && aws eks update-kubeconfig --region $(AWS_REGION) --name `terraform output -raw cluster_name`

awssts:
	aws sts get-caller-identity

cd:
	cd infra/terraform/envs/$(ENV)



