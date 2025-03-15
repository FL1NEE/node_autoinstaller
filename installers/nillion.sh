#!/bin/bash

echo "=== Установка Nillion ==="

# 1. Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y || { echo "Ошибка при обновлении системы."; exit 1; }

# 2. Скачивание скрипта setup.sh
echo "Скачивание скрипта setup.sh..."
wget https://raw.githubusercontent.com/Rambeboy/Nillion-Node/main/setup.sh -O /tmp/nillion-setup.sh || { echo "Ошибка при скачивании скрипта."; exit 1; }

# 3. Делаем скрипт исполняемым
chmod +x /tmp/nillion-setup.sh

# 4. Запуск скрипта setup.sh
echo "Запуск скрипта установки Nillion..."
sudo /tmp/nillion-setup.sh || { echo "Ошибка при установке Nillion."; exit 1; }

echo "Установка завершена. Nillion работает в фоновом режиме."
