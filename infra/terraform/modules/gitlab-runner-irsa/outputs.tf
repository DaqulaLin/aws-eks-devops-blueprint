output "role_arn"   { 
  value = aws_iam_role.gitlab_runner.arn 
  }
output "policy_arn" { 
  value = aws_iam_policy.ecr_minimal.arn 
  }
