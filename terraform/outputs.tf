# terraform/outputs.tf (Updated)

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "configure_kubectl" {
  description = "Run this command to configure kubectl to connect to the EKS cluster."
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "lbc_iam_role_arn" {
  description = "The ARN of the IAM role for the AWS Load Balancer Controller"
  value       = aws_iam_role.lbc_role.arn
}