##########################################
# IAM ROLE FOR ECR ACCESS (Private ECR)
##########################################
resource "aws_iam_role" "apprunner_ecr_access" {
  name = "${var.service_name}-apprunner-ecr-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecr_access_policy" {
  role       = aws_iam_role.apprunner_ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

##########################################
# Instance Role
##########################################
resource "aws_iam_role" "instance_role" {
  name = "${var.service_name}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

##########################################
# APP RUNNER SERVICE
##########################################
resource "aws_apprunner_service" "this" {
  service_name = var.service_name

  source_configuration {
    image_repository {
      image_identifier      = var.image_identifier
      image_repository_type = var.image_repository_type

      image_configuration {
        port = var.port
      }
    }

    # For private ECR authentication
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }
    auto_deployments_enabled = var.auto_deployments_enabled
    # environment_variables    = var.environment_variables
  }
  auto_scaling_configuration_arn = var.auto_scaling_configuration != null ? var.auto_scaling_configuration : null

  network_configuration {
    ingress_configuration {
      is_publicly_accessible = false
    }
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.main.arn
    }
  }
  instance_configuration {
    cpu    = var.cpu
    memory = var.memory
    instance_role_arn = aws_iam_role.instance_role.arn
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/"
    interval            = 5       # seconds between health checks
    timeout             = 5       # seconds to wait for response
    healthy_threshold   = 1       # number of successes to mark healthy
    unhealthy_threshold = 3       # number of failures to mark unhealthy
  }
  tags = {
    Name = var.service_name
  }
}
# Security Group
resource "aws_security_group" "apprunner" {
  name        = "${var.service_name}-apprunner"
  description = "Security group for App Runner VPC connector"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_apprunner_vpc_connector" "main" {
  vpc_connector_name = "${var.service_name}-connector"
  subnets           = var.subnet_ids
  security_groups   = [aws_security_group.apprunner.id]
}

##########################################
# ATTACH VPC INGRESS CONNECTION TO APP RUNNER (Private Traffic)
##########################################
resource "aws_apprunner_vpc_ingress_connection" "private_ingress" {
  name = "${var.service_name}-private-ingress"
  service_arn                 = aws_apprunner_service.this.arn

  ingress_vpc_configuration {
    vpc_id             = var.vpc_id
    vpc_endpoint_id    = aws_vpc_endpoint.apprunner_endpoint.id
  }
}

# VPC Endpoint for App Runner private ingress
resource "aws_vpc_endpoint" "apprunner_endpoint" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.apprunner" # Replace ${var.region} with your AWS region
  vpc_endpoint_type = "Interface"
  subnet_ids        = var.subnet_ids
  security_group_ids = [aws_security_group.apprunner.id]
}
