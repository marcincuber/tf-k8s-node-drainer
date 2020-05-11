variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS region in which resources will get deployed. Defaults to Ireland."
}

variable "subnets" {
  type        = list(string)
  description = "Classless Inter-Domain Routing ranges for private/public subnets."
}

variable "tags" {
  type        = map(string)
  description = "Default tags attached to all resources."
  default     = {}
}

variable "cluster_name" {
  type = string
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group ids"
}

variable "auto_scaling_group_name" {
  type = string
}

variable "name_prefix" {
  type        = string
  description = "name_prefix that will be used across all resources"
}
