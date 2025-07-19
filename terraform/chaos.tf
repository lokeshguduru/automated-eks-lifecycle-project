# This file defines the Chaos Engineering experiment using AWS FIS as code.

# 1. Create an IAM Role for FIS to use
resource "aws_iam_role" "fis_role" {
  name = "${var.project_name}-fis-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "fis.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Attach the necessary policy to the role
resource "aws_iam_role_policy" "fis_policy" {
  name = "${var.project_name}-fis-permissions"
  role = aws_iam_role.fis_role.id

  # This policy grants the exact permissions needed for the experiment
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:TerminateInstances"
        ],
        Resource = "*"
      },
    ]
  })
}

# 3. Define the Chaos Experiment Template
resource "aws_fis_experiment_template" "terminate_eks_node" {
  description = "Terminate one random EKS worker node to test cluster resilience."
  role_arn    = aws_iam_role.fis_role.arn

  # Define the action to take
  action {
    name       = "terminate-node"
    action_id  = "aws:ec2:terminate-instances"
    target {
      key   = "Instances"
      value = "eks_nodes"
    }
  }

  # Define the target resources for the action using the correct syntax
  target {
    name           = "eks_nodes"
    resource_type  = "aws:ec2:instance"
    selection_mode = "COUNT(1)"

    # Use a 'filters' block to select resources based on their tags and state.
    filter {
      path   = "State.Name"
      values = ["running"]
    }
    filter {
      path   = "tag:eks:cluster-name"
      values = [var.project_name]
    }
  }

  # Define a stop condition for safety
  stop_condition {
    source = "none"
  }

  tags = {
    Name = "EKS Node Termination Experiment"
  }
}