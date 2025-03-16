module "vpc" {
  source                                = "terraform-aws-modules/vpc/aws"
  cidr                                  = var.cidr
  azs                                   = var.azs
  private_subnets                       = var.private_subnets_cidr_blocks
  create_private_nat_gateway_route      = true
  tags                                  = var.tags
  vpc_tags                              = var.vpc_tags
}