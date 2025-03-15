#!/bin/bash

echo "=== Установка Farcaster Hubble ==="

# 1. Проверка наличия Docker
echo "Проверка наличия Docker..."
if ! command -v docker &> /dev/null; then
    echo "Docker не найден. Установка Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh || { echo "Ошибка при скачивании скрипта Docker."; exit 1; }
    sudo sh get-docker.sh || { echo "Ошибка при установке Docker."; exit 1; }
    rm get-docker.sh
    sudo usermod -aG docker $USER || { echo "Ошибка при добавлении пользователя в группу docker."; exit 1; }
    echo "Docker успешно установлен. Пожалуйста, перезайдите в систему для применения изменений."
else
    echo "Docker уже установлен."
fi

# 2. Установка Docker Compose
echo "Проверка наличия Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose не найден. Установка Docker Compose..."
    sudo apt update
    sudo apt install -y docker-compose || { echo "Ошибка при установке Docker Compose."; exit 1; }
    echo "Docker Compose успешно установлен."
else
    echo "Docker Compose уже установлен."
fi

# 3. Скачивание и настройка Hubble
echo "Скачивание и настройка Hubble..."
HUBBLE_DIR="$HOME/hubble"
if [ -d "$HUBBLE_DIR" ]; then
    echo "Директория Hubble уже существует. Обновляем..."
    cd "$HUBBLE_DIR" || { echo "Ошибка: Не удалось перейти в директорию $HUBBLE_DIR."; exit 1; }
    git pull origin main || { echo "Ошибка при обновлении репозитория."; exit 1; }
else
    git clone https://github.com/farcasterxyz/hub-monorepo.git "$HUBBLE_DIR" || { echo "Ошибка при клонировании репозитория."; exit 1; }
    cd "$HUBBLE_DIR" || { echo "Ошибка: Не удалось перейти в директорию $HUBBLE_DIR."; exit 1; }
fi

# 4. Установка зависимостей
echo "Установка зависимостей..."
yarn install || { echo "Ошибка при установке зависимостей."; exit 1; }
yarn build || { echo "Ошибка при сборке проекта."; exit 1; }

# 5. Запрос параметров пользователя
echo "Введите ваш L1 Mainnet ETH RPC URL (например, от Alchemy или Infura):"
read -r ETH_MAINNET_RPC_URL
if [ -z "$ETH_MAINNET_RPC_URL" ]; then
    echo "RPC URL не может быть пустым. Установка прервана."
    exit 1
fi

echo "Введите ваш L2 Optimism Mainnet RPC URL:"
read -r OPTIMISM_L2_RPC_URL
if [ -z "$OPTIMISM_L2_RPC_URL" ]; then
    echo "RPC URL не может быть пустым. Установка прервана."
    exit 1
fi

echo "Введите ваш Farcaster FID (ID оператора):"
read -r HUB_OPERATOR_FID
if [ -z "$HUB_OPERATOR_FID" ]; then
    echo "FID не может быть пустым. Установка прервана."
    exit 1
fi

# 6. Создание файла .env
echo "Создание файла .env..."
cd apps/hubble || { echo "Ошибка: Не удалось перейти в директорию apps/hubble."; exit 1; }
cat <<EOL > .env
ETH_MAINNET_RPC_URL=$ETH_MAINNET_RPC_URL
OPTIMISM_L2_RPC_URL=$OPTIMISM_L2_RPC_URL
HUB_OPERATOR_FID=$HUB_OPERATOR_FID
EOL

# 7. Генерация ключей идентификации
echo "Генерация ключей идентификации..."
docker compose run hubble yarn identity create || { echo "Ошибка при генерации ключей идентификации."; exit 1; }

# 8. Запуск Hubble
echo "Запуск Hubble..."
docker compose up hubble -d || { echo "Ошибка при запуске Hubble."; exit 1; }

echo "Установка завершена. Hubble запущен в фоновом режиме."
echo "Чтобы проверить логи, выполните: docker compose logs -f hubble"
