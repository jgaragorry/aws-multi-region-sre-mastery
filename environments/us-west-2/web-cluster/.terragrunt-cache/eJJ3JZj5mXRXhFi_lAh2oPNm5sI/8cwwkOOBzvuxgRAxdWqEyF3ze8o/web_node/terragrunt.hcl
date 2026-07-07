include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules//web_node"
}

inputs = {
  environment   = "us-west-2-backup"
  instance_type = "t3.micro"
  ami_id        = "ami-04430666534a2e226"
}
