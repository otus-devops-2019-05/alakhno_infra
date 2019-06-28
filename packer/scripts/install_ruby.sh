#!/bin/bash
set -e

# Install Ruby
apt update
apt install -y ruby-full ruby-bundler build-essential
