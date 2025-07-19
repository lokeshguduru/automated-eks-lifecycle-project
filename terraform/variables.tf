variable "region" {
  description = "AWS region for the EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name for the EKS cluster and associated resources."
  type        = string
  default     = "eks-3tier-demo"
}