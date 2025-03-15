#!/bin/bash

echo "=== Установка Initia ==="

# 1. Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y || { echo "Ошибка при обновлении системы."; exit 1; }

# 2. Установка Go
echo "Установка Go..."
wget https://go.dev/dl/go1.20.5.linux-amd64.tar.gz -O /tmp/go.tar.gz || { echo "Ошибка при скачивании Go."; exit 1; }
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
export PATH=$PATH:/usr/local/go/bin

# 3. Клонирование репозитория
echo "Клонирование репозитория Initia..."
git clone https://github.com/initia-labs/initia.git /opt/initia || { echo "Ошибка при клонировании репозитория."; exit 1; }
cd /opt/initia || { echo "Ошибка при переходе в директорию /opt/initia."; exit 1; }

# 4. Сборка проекта
echo "Сборка проекта..."
make install || { echo "Ошибка при сборке проекта."; exit 1; }

# 5. Инициализация ноды
echo "Инициализация ноды..."
initiad init MyNode --chain-id=initia-testnet || { echo "Ошибка при инициализации ноды."; exit 1; }

# 6. Загрузка genesis.json
echo "Загрузка genesis.json..."
wget https://raw.githubusercontent.com/initia-labs/initia/main/genesis.json -O ~/.initia/config/genesis.json || { echo "Ошибка при загрузке genesis.json."; exit 1; }

# 7. Запуск ноды
echo "Запуск ноды Initia..."
nohup initiad start > initia.log 2>&1 &
disown

echo "Установка завершена. Логи доступны в ~/.initia/logs/initia.log"
