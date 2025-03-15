#!/bin/bash

echo "=== Установка Hemi ==="

# 1. Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y || { echo "Ошибка при обновлении системы."; exit 1; }

# 2. Установка Go
echo "Установка Go..."
if ! command -v go &> /dev/null; then
    wget https://go.dev/dl/go1.20.5.linux-amd64.tar.gz -O /tmp/go.tar.gz || { echo "Ошибка при скачивании Go."; exit 1; }
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
    echo "Go успешно установлен."
else
    echo "Go уже установлен."
fi

# 3. Клонирование репозитория Hemi
echo "Клонирование репозитория Hemi..."
if [ -d "heminetwork" ]; then
    echo "Репозиторий Hemi уже клонирован. Обновляем..."
    cd heminetwork || { echo "Ошибка: Не удалось перейти в директорию heminetwork."; exit 1; }
    git pull origin main || { echo "Ошибка при обновлении репозитория."; exit 1; }
else
    git clone https://github.com/hemilabs/heminetwork.git || { echo "Ошибка при клонировании репозитория."; exit 1; }
    cd heminetwork || { echo "Ошибка: Не удалось перейти в директорию heminetwork."; exit 1; }
fi

# 4. Установка зависимостей
echo "Установка зависимостей..."
go mod tidy || { echo "Ошибка при установке зависимостей."; exit 1; }

# 5. Сборка проекта
echo "Сборка проекта..."
go build -o hemi-node ./cmd/hemi || { echo "Ошибка при сборке проекта."; exit 1; }

# 6. Запуск ноды
echo "Запуск ноды Hemi..."
nohup ./hemi-node > hemi.log 2>&1 &
disown

echo "Установка завершена. Логи доступны в файле hemi.log"
