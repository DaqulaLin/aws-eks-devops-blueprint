output "role_arn" {
  description = "IAM role ARN for Dev SSM IRSA"
  value       = aws_iam_role.this.arn
}

output "policy_arn" {
  description = "IAM policy ARN (minimal eso-dev SSM)"
  value       = aws_iam_policy.ssm_minimal.arn
}

output "role_name" {
  description = "IAM role name"
  value       = aws_iam_role.this.name
}

