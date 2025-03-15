#!/bin/bash

echo "=== Установка Titan Agent ==="

# 1. Проверка наличия Snap
echo "Проверка наличия Snap..."
if ! command -v snap &> /dev/null; then
    echo "Snap не найден. Установка Snap..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian)
                sudo apt update
                sudo apt install -y snapd || { echo "Ошибка при установке Snap."; exit 1; }
                ;;
            fedora)
                sudo dnf install -y snapd || { echo "Ошибка при установке Snap."; exit 1; }
                ;;
            centos|rhel)
                sudo yum install -y snapd || { echo "Ошибка при установке Snap."; exit 1; }
                ;;
            *)
                echo "Ваша система не поддерживается для автоматической установки Snap."
                exit 1
                ;;
        esac
        sudo systemctl enable --now snapd.socket || { echo "Ошибка при включении Snap."; exit 1; }
    else
        echo "Не удалось определить дистрибутив Linux."
        exit 1
    fi
else
    echo "Snap уже установлен."
fi

# 2. Установка Multipass
echo "Установка Multipass..."
sudo snap install multipass || { echo "Ошибка при установке Multipass."; exit 1; }
multipass --version || { echo "Multipass не установлен корректно."; exit 1; }

# 3. Скачивание и распаковка пакета Titan Agent
echo "Скачивание и распаковка пакета Titan Agent..."
AGENT_DIR="/opt/titanagent"
if [ -d "$AGENT_DIR" ]; then
    echo "Директория $AGENT_DIR уже существует. Обновляем..."
    sudo rm -rf "$AGENT_DIR" || { echo "Ошибка при удалении старой директории."; exit 1; }
fi

sudo mkdir -p "$AGENT_DIR" || { echo "Ошибка при создании директории $AGENT_DIR."; exit 1; }
wget https://pcdn.titannet.io/test4/bin/agent-linux.zip -O /tmp/agent-linux.zip || { echo "Ошибка при скачивании пакета."; exit 1; }
sudo unzip /tmp/agent-linux.zip -d "$AGENT_DIR" || { echo "Ошибка при распаковке пакета."; exit 1; }
rm /tmp/agent-linux.zip

# 4. Добавление прав на выполнение
echo "Добавление прав на выполнение..."
sudo chmod +x "$AGENT_DIR/agent" || { echo "Ошибка при добавлении прав на выполнение."; exit 1; }

# 5. Запрос ключа пользователя
echo "Введите ваш ключ Titan Network:"
read -r TITAN_KEY
if [ -z "$TITAN_KEY" ]; then
    echo "Ключ не может быть пустым. Установка прервана."
    exit 1
fi

# 6. Запуск Titan Agent
echo "Запуск Titan Agent..."
cd "$AGENT_DIR" || { echo "Ошибка: Не удалось перейти в директорию $AGENT_DIR."; exit 1; }
nohup sudo ./agent \
    --working-dir="$AGENT_DIR" \
    --server-url="https://test4-api.titannet.io" \
    --key="$TITAN_KEY" > titan-agent.log 2>&1 &
disown

echo "Установка завершена. Логи доступны в файле $AGENT_DIR/titan-agent.log"
