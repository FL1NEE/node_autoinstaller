#!/bin/bash

# Скрипт автоматической установки Hemi PoP ноды для Linux (amd64)
# Требует запуска от root (sudo)

# Конфигурация
HEMI_VERSION="v1.0.0"                     # Версия Hemi Network
HEMI_PACKAGE="heminetwork_${HEMI_VERSION}_linux_amd64.tar.gz"
BFG_URL="wss://pop.hemi.network/v1/ws/public" # BFG endpoint
NETWORK="mainnet"                          # mainnet или testnet
FEE_RATE=3                                 # Satoshi per vByte (рекомендуется проверять на mempool.space)

# 1. Установка зависимостей
echo "Устанавливаем системные зависимости..."
apt-get update
apt-get install -y wget curl tar git build-essential

# 2. Создание пользователя hemi
echo "Создаем системного пользователя..."
useradd -m -s /bin/bash hemi
usermod -a -G sudo hemi
echo "hemi ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 3. Загрузка и распаковка бинарников
echo "Загружаем Hemi Network CLI..."
wget https://github.com/hemilabs/heminetwork/releases/download/${HEMI_VERSION}/${HEMI_PACKAGE} -O /tmp/${HEMI_PACKAGE}

echo "Распаковываем архив..."
tar -xzf /tmp/${HEMI_PACKAGE} -C /home/hemi/
chown -R hemi:hemi /home/hemi/heminetwork*

# 4. Настройка окружения
echo "Настраиваем переменные окружения..."
sudo -u hemi bash -c "echo 'export PATH=\$PATH:/home/hemi/heminetwork_${HEMI_VERSION}_linux_amd64' >> ~/.bashrc"

# 5. Генерация ключей (если нет существующего)
echo "Генерируем новые ключи..."
sudo -u hemi /home/hemi/heminetwork_${HEMI_VERSION}_linux_amd64/keygen -secp256k1 -json > /home/hemi/popm-address.json

# 6. Настройка сервиса systemd
echo "Создаем systemd сервис..."
cat <<EOF > /etc/systemd/system/hemi-pop.service
[Unit]
Description=Hemi PoP Miner
After=network.target

[Service]
User=hemi
Environment="POPM_BTC_PRIVKEY=\$(jq -r '.private_key' /home/hemi/popm-address.json)"
Environment="POPM_STATIC_FEE=${FEE_RATE}"
Environment="POPM_BFG_URL=${BFG_URL}"
Environment="POPM_BTC_CHAIN_NAME=${NETWORK}"
WorkingDirectory=/home/hemi
ExecStart=/home/hemi/heminetwork_${HEMI_VERSION}_linux_amd64/popmd
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 7. Запуск сервиса
systemctl daemon-reload
systemctl enable hemi-pop
systemctl start hemi-pop

echo "Установка завершена!"
echo "Статус ноды можно проверить командой: systemctl status hemi-pop"
echo "Приватный ключ и адрес: /home/hemi/popm-address.json"
echo "Не забудьте пополнить BTC адрес для оплаты транзакций!"
