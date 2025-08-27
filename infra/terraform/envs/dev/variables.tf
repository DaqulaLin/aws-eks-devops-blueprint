variable "project_name" {
  type    = string
  default = "project-eks"
}
variable "env" {
  type    = string
  default = "dev"
}
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
variable "public_subnets" {
  type    = list(string)
  default = ["10.10.1.0/24", "10.10.2.0/24"]
}
variable "private_subnets" {
  type    = list(string)
  default = ["10.10.11.0/24", "10.10.12.0/24"]
}

variable "eks_version" {
  type    = string
  default = "1.32"
}
variable "node_instance_types" {
  type    = list(string)
  default = ["t3.small"]
}
variable "node_desired_size" {
  type    = number
  default = 2
}
variable "node_min_size" {
  type    = number
  default = 1
}
variable "node_max_size" {
  type    = number
  default = 4
}



variable "create_ecr" {
  type    = bool
  default = true
}
variable "ecr_repo_name" {
  type    = string
  default = "myapp"
}

# 实验期：节点放公有子网更省钱
variable "use_public_nodes" {
  type    = bool
  default = true # 实验/演示=true；生产切换时改为 false
}

# 生产期：是否启用 NAT 网关（私网节点需要）
variable "enable_nat" {
  type    = bool
  default = false # 实验/演示=false；生产切换时改为 true
}



variable "oidc_provider_arn" { type = string }