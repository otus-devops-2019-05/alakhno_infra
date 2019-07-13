provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}

module "app" {
  source           = "../modules/app"
  env              = "stage"
  public_key_path  = "${var.public_key_path}"
  private_key_path = "${var.private_key_path}"
  zone             = "${var.zone}"
  app_disk_image   = "${var.app_disk_image}"
  database_url     = "${module.db.db_external_ip}:27017"
  app_deploy       = "${var.app_deploy}"
}

module "db" {
  source           = "../modules/db"
  env              = "stage"
  public_key_path  = "${var.public_key_path}"
  private_key_path = "${var.private_key_path}"
  zone             = "${var.zone}"
  db_disk_image    = "${var.db_disk_image}"
}

module "vpc" {
  source        = "../modules/vpc"
  env           = "stage"
  source_ranges = ["0.0.0.0/0"]
}
