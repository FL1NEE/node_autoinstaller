#!/bin/bash

# Скрипт автоматической установки Hemi PoP ноды для Linux (amd64)
# Требует запуска от root (sudo)

# Проверка прав
if [ "$EUID" -ne 0 ]; then
  echo "Запустите скрипт с правами root: sudo $0"
  exit 1
fi

# Конфигурация
HEMI_VERSION="v1.0.0"                     
HEMI_PACKAGE="heminetwork_${HEMI_VERSION}_linux_amd64.tar.gz"
BFG_URL="wss://pop.hemi.network/v1/ws/public"

# Диалог выбора сети
PS3='Выберите сеть для работы: '
options=("Mainnet" "Testnet")
select opt in "${options[@]}"
do
  case $opt in
    "Mainnet")
      NETWORK="mainnet"
      FEE_RATE=3
      break
      ;;
    "Testnet")
      NETWORK="testnet"
      FEE_RATE=1
      break
      ;;
    *) echo "Неверный вариант $REPLY";;
  esac
done

# Диалог выбора кошелька
echo
PS3='Использовать существующий кошелек или создать новый? '
wallet_options=("Создать новый кошелек" "Использовать существующий приватный ключ")
select wallet_opt in "${wallet_options[@]}"
do
  case $wallet_opt in
    "Создать новый кошелек")
      NEW_KEY=true
      break
      ;;
    "Использовать существующий приватный ключ")
      NEW_KEY=false
      read -p "Введите приватный ключ (hex формат): " PRIV_KEY
      if [ -z "$PRIV_KEY" ]; then
        echo "Приватный ключ не может быть пустым!"
        exit 1
      fi
      break
      ;;
    *) echo "Неверный вариант $REPLY";;
  esac
done

# 1. Установка зависимостей
echo
echo "Обновляем систему и устанавливаем зависимости..."
apt-get update && apt-get upgrade -y
apt-get install -y wget curl tar jq git build-essential

# 2. Создание пользователя hemi
if ! id "hemi" &>/dev/null; then
  echo "Создаем системного пользователя..."
  useradd -m -s /bin/bash hemi
  usermod -a -G sudo hemi
  echo "hemi ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# 3. Загрузка и распаковка бинарников
echo "Загружаем Hemi Network CLI..."
wget -q https://github.com/hemilabs/heminetwork/releases/download/${HEMI_VERSION}/${HEMI_PACKAGE} -O /tmp/${HEMI_PACKAGE}

if [ ! -f "/tmp/${HEMI_PACKAGE}" ]; then
  echo "Ошибка загрузки пакета!"
  exit 1
fi

echo "Распаковываем архив..."
tar -xzf /tmp/${HEMI_PACKAGE} -C /home/hemi/
chown -R hemi:hemi /home/hemi/heminetwork*

# 4. Генерация или сохранение ключа
if [ "$NEW_KEY" = true ]; then
  echo "Генерируем новые ключи..."
  sudo -u hemi /home/hemi/heminetwork_${HEMI_VERSION}_linux_amd64/keygen -secp256k1 -json > /home/hemi/popm-address.json
  PRIV_KEY=$(jq -r '.private_key' /home/hemi/popm-address.json)
else
  echo "Создаем файл ключа..."
  sudo -u hemi bash -c "jq -n --arg priv \"$PRIV_KEY\" '{private_key: \$priv}' > /home/hemi/popm-address.json"
fi

# 5. Настройка сервиса systemd
echo "Создаем systemd сервис..."
cat <<EOF > /etc/systemd/system/hemi-pop.service
[Unit]
Description=Hemi PoP Miner
After=network.target

[Service]
User=hemi
Environment="POPM_BTC_PRIVKEY=${PRIV_KEY}"
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

# 6. Запуск сервиса
systemctl daemon-reload
systemctl enable hemi-pop
systemctl start hemi-pop

# 7. Информация для пользователя
echo
echo "Установка завершена!"
echo "Статус ноды: systemctl status hemi-pop"
echo
echo "=== Важные данные ==="
echo "Сеть: ${NETWORK}"
echo "Приватный ключ: ${PRIV_KEY}"
echo "BTC Адрес: $(jq -r '.pubkey_hash' /home/hemi/popm-address.json)"
echo
echo "Для ${NETWORK} пополните адрес BTC!"
if [ "$NETWORK" = "testnet" ]; then
  echo "Получить tBTC можно здесь: https://bitcoinfaucet.uo1.net/"
fi
