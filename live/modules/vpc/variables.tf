
variable "azs" {
    description = "A list for availability zones"
    type        = list(string)
}

variable "cidr" {
    description = "The CIDR block of the VPC"
    type        = string
}

variable "private_subnets_cidr_blocks" {
    description = "List of cidr_blocks of private subnets"
    type        = list(string)
}

variable "create_private_nat_gateway_route" {
  description = "Controls if a nat gateway route should be created to give internet access to the private subnets"
  type        = bool
  default     = true
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
