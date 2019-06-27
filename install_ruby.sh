#!/bin/bash

# Обновляем APT и устанавливаем Ruby и Bundler
sudo apt update
sudo apt install -y ruby-full ruby-bundler build-essential

# Проверяем Ruby и Bundler
ruby -v
bundler -v
