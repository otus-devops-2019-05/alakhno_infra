terraform {
  backend "gcs" {
    bucket = "otus-devops"
    prefix = "prod"
  }
}
