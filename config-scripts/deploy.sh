#!/bin/bash

# Копируем код приложения
git clone -b monolith https://github.com/express42/reddit.git

# Устанавливаем зависимости приложения
cd reddit && bundle install

# Запускаем сервер приложения
puma -d

# Проверяем, что сервер запустился
ps aux | grep puma
