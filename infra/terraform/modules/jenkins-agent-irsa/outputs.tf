output "role_arn" {
  description = "IAM role ARN for Jenkins Agent IRSA"
  value       = aws_iam_role.this.arn
}

output "policy_arn" {
  description = "IAM policy ARN (minimal ECR)"
  value       = aws_iam_policy.ecr_minimal.arn
}

output "role_name" {
  description = "IAM role name"
  value       = aws_iam_role.this.name
}
