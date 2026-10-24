variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type        = string
  default     = "t4g.small" # 2 vCPU ARM, 2 GB. Use t3.small for x86.
  description = "Smallest size that fits k3s + the API (~1.5 GB usable)."
}

variable "architecture" {
  type        = string
  default     = "arm64" # must match instance_type: arm64 for t4g, amd64 for t3
  description = "AMI architecture."
}

variable "monthly_budget_usd" {
  type    = number
  default = 15
}

variable "alert_email" {
  type        = string
  description = "Where budget alerts go."
}
