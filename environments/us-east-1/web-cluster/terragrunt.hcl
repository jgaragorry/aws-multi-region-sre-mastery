include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//web_node"
}

inputs = {
  ami_id        = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS en us-east-1
  instance_type = "t3.micro"
  environment   = "us-east-1-prod"
}
