#!/bin/bash

echo "=== Установка Farcaster ==="

# 1. Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y || { echo "Ошибка при обновлении системы."; exit 1; }

# 2. Установка Node.js и npm
echo "Установка Node.js и npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - || { echo "Ошибка при добавлении репозитория Node.js."; exit 1; }
sudo apt install -y nodejs || { echo "Ошибка при установке Node.js."; exit 1; }

# 3. Клонирование репозитория
echo "Клонирование репозитория Farcaster..."
git clone https://github.com/farcasterxyz/hub.git /opt/farcaster || { echo "Ошибка при клонировании репозитория."; exit 1; }
cd /opt/farcaster || { echo "Ошибка при переходе в директорию /opt/farcaster."; exit 1; }

# 4. Установка зависимостей
echo "Установка зависимостей..."
npm install || { echo "Ошибка при установке зависимостей."; exit 1; }

# 5. Запрос ключа у пользователя
read -p "Введите ваш ключ (--key): " user_key

if [ -z "$user_key" ]; then
    echo "Ошибка: Ключ не может быть пустым."
    exit 1
fi

# 6. Запуск ноды
echo "Запуск ноды Farcaster..."
nohup npm start -- --key="$user_key" > farcaster.log 2>&1 &
disown

echo "Установка завершена. Логи доступны в /opt/farcaster/farcaster.log"
