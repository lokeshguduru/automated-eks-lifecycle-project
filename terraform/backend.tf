# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-bucket"
#     key            = "eks-3tier/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }