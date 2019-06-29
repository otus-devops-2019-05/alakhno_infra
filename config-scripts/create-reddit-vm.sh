#!/bin/bash

gcloud compute instances create reddit-app \
  --image-family reddit-full \
  --machine-type=f1-micro \
  --tags=puma-server
