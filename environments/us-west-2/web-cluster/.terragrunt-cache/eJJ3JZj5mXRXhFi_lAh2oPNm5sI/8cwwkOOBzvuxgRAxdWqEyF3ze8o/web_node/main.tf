terraform {
  backend "s3" {}
}

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name      = "sre-node-${var.environment}"
    Env       = var.environment
    ManagedBy = "Terraform-Core"
    Lab       = "iac-mastery_7"
  }
}

resource "aws_ssm_parameter" "node_status" {
  name        = "/sre/infra/${var.environment}/status"
  type        = "String"
  value       = "Nodo activo en region ${var.environment}"
  description = "Estado operativo en iac-mastery_7"
}
