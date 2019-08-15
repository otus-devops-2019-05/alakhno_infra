#!/bin/bash
set -e

# Create keys
touch ~/.ssh/appuser.pub ~/.ssh/appuser

for env in stage prod; do
  echo Validating $env
  cd terraform/$env
  terraform init -backend=false
  terraform validate -var-file=terraform.tfvars.example
  tflint --var-file=terraform.tfvars.example
  cd -
done
