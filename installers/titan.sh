#!/bin/bash

echo "=== Установка Titan Network ==="

# 1. Скачивание агента
echo "Скачивание агента Titan Network..."
wget https://pcdn.titannet.io/test4/bin/agent-linux.zip -O /tmp/agent-linux.zip || { echo "Ошибка при скачивании агента."; exit 1; }


mkdir -p /opt/titanagent
# 2. Распаковка агента
echo "Распаковка агента..."
unzip /tmp/agent-linux.zip -d /opt/titanagent || { echo "Ошибка при распаковке агента."; exit 1; }
rm /tmp/agent-linux.zip

# 3. Запрос ключа у пользователя
read -p "Введите ваш ключ (--key): " user_key

if [ -z "$user_key" ]; then
    echo "Ошибка: Ключ не может быть пустым."
    exit 1
fi

# 4. Запуск агента
echo "Запуск агента Titan Network..."
cd /opt/titanagent || { echo "Ошибка при переходе в директорию."; exit 1; }
nohup ./agent --working-dir=/opt/titanagent --server-url=https://test4-api.titannet.io --key="$user_key" > agent.log 2>&1 &
disown

echo "Установка завершена. Логи доступны в /opt/titanagent/agent.log"
