variable "az_count" {
  type        = number
  default     = 2
  description = "Number of AZs to spread subnets across"
}

variable "enable_nat_gateway" {
  type        = bool
  default     = false
  description = "Enable NAT gateway for private subnets (~$0.045/hr)"
}
