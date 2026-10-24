terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # State is local for learning. Production would use an S3 backend with locking.
}

provider "aws" {
  region = var.region
}

# ---- Network: reuse the default VPC (free, no NAT gateway cost) ----
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ---- AMI: latest Ubuntu 24.04 (arm64 for t4g), resolved via Canonical's public SSM parameter ----
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/${var.architecture}/hvm/ebs-gp3/ami-id"
}

# ---- Security group: web traffic only. No SSH; admin access goes through SSM ----
resource "aws_security_group" "node" {
  name_prefix = "rag-k3s-"
  description = "HTTP/HTTPS in, everything out"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---- IAM: lets the instance register with SSM Session Manager (shell without SSH keys) ----
resource "aws_iam_role" "node" {
  name_prefix = "rag-k3s-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "node" {
  name_prefix = "rag-k3s-"
  role        = aws_iam_role.node.name
}

# ---- The node: one small EC2 instance running k3s ----
resource "aws_instance" "node" {
  ami                    = nonsensitive(data.aws_ssm_parameter.ubuntu.value)
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.node.id]
  iam_instance_profile   = aws_iam_instance_profile.node.name
  user_data              = file("${path.module}/user_data.sh")

  # IMDSv2 only: blocks the classic SSRF-to-credentials attack
  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "rag-k3s" }
}

# Stable public IP so DNS / CI don't break when the instance stops and starts
resource "aws_eip" "node" {
  instance = aws_instance.node.id
  domain   = "vpc"
}

# ---- Cost guardrail: email when forecast spend nears the limit ----
resource "aws_budgets_budget" "monthly" {
  name         = "rag-k3s-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}
