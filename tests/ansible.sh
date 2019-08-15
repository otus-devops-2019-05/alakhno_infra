#!/bin/bash
set -e

ansible-lint ansible/playbooks/*.yml
