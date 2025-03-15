#!/bin/bash

echo "=== Установка Hemi ==="

# 1. Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y || { echo "Ошибка при обновлении системы."; exit 1; }

# 2. Установка Node.js и npm
echo "Установка Node.js и npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || { echo "Ошибка при добавлении репозитория Node.js."; exit 1; }
sudo apt install -y nodejs || { echo "Ошибка при установке Node.js."; exit 1; }

# 3. Клонирование репозитория
echo "Клонирование репозитория Hemi..."
git clone https://github.com/hemilabs/heminetwork /opt/hemi || { echo "Ошибка при клонировании репозитория."; exit 1; }
cd /opt/hemi || { echo "Ошибка при переходе в директорию /opt/hemi."; exit 1; }

# 4. Установка зависимостей
echo "Установка зависимостей..."
npm install || { echo "Ошибка при установке зависимостей."; exit 1; }

# 5. Запуск ноды
echo "Запуск ноды Hemi..."
nohup npm start > hemi.log 2>&1 &
disown

echo "Установка завершена. Логи доступны в /opt/hemi/hemi.log"
