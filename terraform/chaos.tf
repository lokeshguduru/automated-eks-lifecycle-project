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
resource "aws_iam_role_policy_attachment" "fis_ec2_access" {
  role       = aws_iam_role.fis_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSFaultInjectionSimulatorEC2Access"
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

  # Define the target resources for the action
  target {
    name           = "eks_nodes"
    resource_type  = "aws:ec2:instance"
    selection_mode = "COUNT(1)"

    # This filter selects running instances that have the correct cluster tag.
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