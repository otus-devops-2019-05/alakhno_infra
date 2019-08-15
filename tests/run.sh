#!/bin/bash
set -e

echo "Run own tests"
docker exec -e USER=appuser hw-test tests/packer.sh
docker exec -e USER=appuser hw-test tests/terraform.sh
docker exec -e USER=appuser hw-test tests/ansible.sh
