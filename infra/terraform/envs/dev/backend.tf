terraform {
  backend "s3" {
    bucket         = "my-terraform-state-daqula"
    key            = "project-eks/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-locks"
    encrypt        = true
  }
}
