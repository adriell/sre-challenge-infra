# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform and OpenTofu that helps keep your code DRY and
# maintainable: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Include the root `terragrunt.hcl` configuration. The root configuration contains settings that are common across all
# components and environments, such as how to configure remote state.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Configure the version of the module to use in this environment. This allows you to promote new versions one
# environment at a time (e.g., qa -> stage -> prod).
terraform {
  source = "../../../modules/vpc/"
}

# ---------------------------------------------------------------------------------------------------------------------
# Override parameters for this environment
# ---------------------------------------------------------------------------------------------------------------------

# For production, we want to specify bigger instance classes and storage, so we specify override parameters here. These
# inputs get merged with the common inputs from the root and the envcommon terragrunt.hcl
inputs = {
  name = "sre-challenge-vpc"
  cidr = "172.16.0.0/27"
  
  azs                           = ["us-east-1a","us-east-1b"]
  private_subnets_cidr_blocks   = ["172.16.0.0/28","172.16.0.16/28"]
  
  vpc_tags = {
    Project    = "sre-challenge"
    Owner      = "SRE Team"
    CostCenter = "Fintech Capivara" 
  }
  tags = {
    Terraform = "true"
  }
  allocated_storage = 100
}