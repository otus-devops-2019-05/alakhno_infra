variable "env" {
  description = "Environment: stage, prod, etc."
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable zone {
  description = "Zone"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable database_url {
  description = "Database url"
}

variable app_deploy {
  description = "Enable app deploy"
}
