variable "name" {
  type        = string
  description = "Name prefix for all resources"
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
  validation {
    condition     = var.az_count >= 2
    error_message = "az_count must be at least 2 (ALB requires subnets in 2+ AZs)."
  }
}

variable "enable_nat_gateway" {
  type        = bool
  default     = false
  description = "Single NAT gateway for private subnets (costs ~$0.045/hr)"
}

variable "tags" {
  type    = map(string)
  default = {}
}
