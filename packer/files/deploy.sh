#!/bin/bash

git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install

mv /tmp/reddit.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable reddit
