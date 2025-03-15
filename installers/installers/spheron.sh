#!/bin/bash

echo "=== Установка Spheron Network ==="

# 1. Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y || { echo "Ошибка при обновлении системы."; exit 1; }

# 2. Установка Node.js и npm
echo "Установка Node.js и npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || { echo "Ошибка при добавлении репозитория Node.js."; exit 1; }
sudo apt install -y nodejs || { echo "Ошибка при установке Node.js."; exit 1; }

# 3. Клонирование репозитория
echo "Клонирование репозитория Spheron..."
git clone https://github.com/spheron-network/spheron-node.git /opt/spheron || { echo "Ошибка при клонировании репозитория."; exit 1; }
cd /opt/spheron || { echo "Ошибка при переходе в директорию /opt/spheron."; exit 1; }

# 4. Установка зависимостей
echo "Установка зависимостей..."
npm install || { echo "Ошибка при установке зависимостей."; exit 1; }

# 5. Запуск ноды
echo "Запуск ноды Spheron..."
nohup npm start > spheron.log 2>&1 &
disown

echo "Установка завершена. Логи доступны в /opt/spheron/spheron.log"
