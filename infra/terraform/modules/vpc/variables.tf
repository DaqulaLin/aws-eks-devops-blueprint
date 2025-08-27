variable "name_prefix" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "tags" { type = map(string) }
variable "enable_nat" { type = bool }
