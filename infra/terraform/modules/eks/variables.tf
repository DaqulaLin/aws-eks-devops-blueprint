variable "name_prefix" { type = string }
variable "eks_version" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "public_subnet_ids" { type = list(string) }
variable "node_instance_types" { type = list(string) }
variable "node_desired_size" { type = number }
variable "node_min_size" { type = number }
variable "node_max_size" { type = number }
variable "tags" { type = map(string) }
variable "use_public_nodes" { type = bool }

variable "enable_prefix_delegation" {
  type    = bool
  default = false
}

variable "upgrade_policy" {
  description = "EKS 升级策略，STANDARD 或 EXTENDED"
  type = object({
    support_type = string
  })
  default = { support_type = "STANDARD" }

  validation {
    condition     = contains(["STANDARD", "EXTENDED"], upper(var.upgrade_policy.support_type))
    error_message = "upgrade_policy.support_type 必须是 STANDARD 或 EXTENDED。"
  }
}

