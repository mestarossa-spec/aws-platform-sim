variable "name" {
  type = string
}

variable "alert_email" {
  type        = string
  description = "Email for SNS alerts (supply via TF_VAR_alert_email, do not commit)"
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "service_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
