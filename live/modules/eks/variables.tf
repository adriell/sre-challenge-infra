variable "name" {
    description = "Cluster Name"
    type        = string
}

variable "vpc_id" {
    description = "The ID of VPC"
    type        = string
}

variable "private_subnets" {
    description = "List of private subnets ID"
    type        = list(string)
}

variable "instance_types" {
    description = "Types of instances"
    type        = list(string)
    default     = ["t3.medium"]
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_version" {
    description = "Cluster Version"
    type        = string
    default     = "1.32"
}