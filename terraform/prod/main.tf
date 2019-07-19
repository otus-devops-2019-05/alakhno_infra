provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "app" {
  source           = "../modules/app"
  env              = "prod"
  public_key_path  = "${var.public_key_path}"
  private_key_path = "${var.private_key_path}"
  zone             = "${var.zone}"
  app_disk_image   = "${var.app_disk_image}"
  database_url     = "${module.db.db_external_ip}:27017"
  app_deploy       = "${var.app_deploy}"
}

module "db" {
  source           = "../modules/db"
  env              = "prod"
  public_key_path  = "${var.public_key_path}"
  private_key_path = "${var.private_key_path}"
  zone             = "${var.zone}"
  db_disk_image    = "${var.db_disk_image}"
  db_bind_ip_all   = "${var.db_bind_ip_all}"
}

module "vpc" {
  source        = "../modules/vpc"
  env           = "prod"
  source_ranges = ["${var.ssh_source_ip}/32"]
}
