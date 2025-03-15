#!/bin/bash

echo "=== Установка PowerLoom ==="

# 1. Обновление системы
echo "Обновление системы..."
sudo apt update && sudo apt upgrade -y || { echo "Ошибка при обновлении системы."; exit 1; }

# 2. Проверка и установка Python 3.10
echo "Проверка версии Python..."
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
if [[ "$PYTHON_VERSION" != "3.10"* ]]; then
    echo "Установка Python 3.10..."
    sudo apt install software-properties-common -y || { echo "Ошибка при установке software-properties-common."; exit 1; }
    sudo add-apt-repository ppa:deadsnakes/ppa -y || { echo "Ошибка при добавлении PPA для Python."; exit 1; }
    sudo apt update
    sudo apt install python3.10 -y || { echo "Ошибка при установке Python 3.10."; exit 1; }
    echo "Python 3.10 успешно установлен."
else
    echo "Python 3.10 уже установлен."
fi

# 3. Установка Docker
echo "Проверка наличия Docker..."
if ! command -v docker &> /dev/null; then
    echo "Docker не найден. Установка Docker..."
    sudo apt install docker.io -y || { echo "Ошибка при установке Docker."; exit 1; }
    sudo systemctl start docker || { echo "Ошибка при запуске Docker."; exit 1; }
    sudo systemctl enable docker || { echo "Ошибка при включении Docker."; exit 1; }
else
    echo "Docker уже установлен."
fi

# 4. Установка Docker Compose
echo "Проверка наличия Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose не найден. Установка Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || { echo "Ошибка при скачивании Docker Compose."; exit 1; }
    sudo chmod +x /usr/local/bin/docker-compose || { echo "Ошибка при назначении прав Docker Compose."; exit 1; }
    echo "Docker Compose успешно установлен."
else
    echo "Docker Compose уже установлен."
fi

# 5. Клонирование репозитория PowerLoom
echo "Клонирование репозитория PowerLoom..."
POWERLOOM_DIR="$HOME/powerloom"
if [ -d "$POWERLOOM_DIR" ]; then
    echo "Репозиторий PowerLoom уже клонирован. Обновляем..."
    cd "$POWERLOOM_DIR" || { echo "Ошибка: Не удалось перейти в директорию $POWERLOOM_DIR."; exit 1; }
    git pull origin simulation_mode || { echo "Ошибка при обновлении репозитория."; exit 1; }
else
    git clone -b simulation_mode https://github.com/PowerLoom/snapshotter-lite powerloom || { echo "Ошибка при клонировании репозитория."; exit 1; }
    cd "$POWERLOOM_DIR" || { echo "Ошибка: Не удалось перейти в директорию $POWERLOOM_DIR."; exit 1; }
fi

# 6. Запрос данных пользователя
echo "Введите Ethereum Mainnet RPC URL (например, от Ankr, Infura или Alchemy):"
read -r SOURCE_RPC_URL
if [ -z "$SOURCE_RPC_URL" ]; then
    echo "RPC URL не может быть пустым. Установка прервана."
    exit 1
fi

echo "Введите адрес вашего кошелька (например, 0x...):"
read -r SIGNER_ACCOUNT_ADDRESS
if [ -z "$SIGNER_ACCOUNT_ADDRESS" ]; then
    echo "Адрес кошелька не может быть пустым. Установка прервана."
    exit 1
fi

echo "Введите приватный ключ вашего кошелька (без 0x в начале):"
read -r SIGNER_ACCOUNT_PRIVATE_KEY
if [ -z "$SIGNER_ACCOUNT_PRIVATE_KEY" ]; then
    echo "Приватный ключ не может быть пустым. Установка прервана."
    exit 1
fi

# 7. Запуск скрипта build.sh
echo "Запуск скрипта build.sh..."
export SOURCE_RPC_URL="$SOURCE_RPC_URL"
export SIGNER_ACCOUNT_ADDRESS="$SIGNER_ACCOUNT_ADDRESS"
export SIGNER_ACCOUNT_PRIVATE_KEY="$SIGNER_ACCOUNT_PRIVATE_KEY"
./build.sh || { echo "Ошибка при выполнении скрипта build.sh."; exit 1; }

echo "Установка завершена. PowerLoom запущен."
