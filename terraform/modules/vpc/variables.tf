variable "env" {
  description = "Environment: stage, prod, etc."
}

variable source_ranges {
  description = "Allowed IP addresses"
  default     = ["0.0.0.0/0"]
}
