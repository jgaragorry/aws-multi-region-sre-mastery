# ~/sre-linux-mastery/Fase2/iac-mastery_7/root.hcl

# Forzar de forma nativa que todo el laboratorio use el binario oficial de Terraform
terraform_binary = "terraform"

remote_state {
  backend = "s3"
  config = {
    bucket  = "garagorry-sre-tfstate-global"
    key     = "iac-mastery_7/${path_relative_to_include()}/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}

locals {
  # Ajuste fino de rutas para parsear la región de forma segura
  path_parts = split("/", path_relative_to_include())
  aws_region = local.path_parts[1]
}
