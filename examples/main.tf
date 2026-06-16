# A small, provider-less Terraform module used to demonstrate terraform-docs.
#
# It declares a couple of inputs and an output with descriptions so that
# `terraform-docs markdown .` renders non-empty Inputs/Outputs tables without
# needing any providers or network access.

terraform {
  required_version = ">= 1.0"
}

variable "name" {
  description = "Name to greet"
  type        = string
  default     = "world"
}

variable "enabled" {
  description = "Whether the greeting is enabled"
  type        = bool
  default     = true
}

output "greeting" {
  description = "A friendly greeting built from var.name"
  value       = "Hello, ${var.name}!"
}
