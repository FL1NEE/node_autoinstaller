#!/bin/bash

echo "=== Установка eOracle ==="

# 1. Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y || { echo "Ошибка при обновлении системы."; exit 1; }

# 2. Установка Docker
echo "Установка Docker..."
sudo apt install -y docker.io || { echo "Ошибка при установке Docker."; exit 1; }

# 3. Запуск контейнера eOracle
echo "Запуск контейнера eOracle..."
docker run -d --name eoracle-node -p 8545:8545 eoracle/node:latest || { echo "Ошибка при запуске контейнера."; exit 1; }

echo "Установка завершена. eOracle работает на порту 8545."
