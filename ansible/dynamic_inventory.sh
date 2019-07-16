#!/bin/bash
set -e

cd ../terraform/stage/
terraform init > /dev/null
APP_IP=`terraform output app_external_ip`
DB_IP=`terraform output db_external_ip`
cd - > /dev/null

envsubst <<EOF
{
  "_meta": {
    "hostvars": {}
  },
  "app": {
    "children": ["appserver"]
  },
  "db": {
    "children": ["dbserver"]
  },
  "appserver": ["${APP_IP}"],
  "dbserver": ["${DB_IP}"]
}
EOF
