# -*- coding: utf-8 -*-
import os
import subprocess
import requests
import json

# Путь к файлу для хранения данных прокси
PROXY_DATA_FILE: str = "proxy_data.json"

# Список доступных проектов
PROJECTS: dict = \
{
    1: {"name": "Hemi", "url": "https://hemi.xyz/", "installer": "installers/hemi.sh", "installed": False},
    2: {"name": "Powerloom", "url": "https://docs.powerloom.io/", "installer": "installers/powerloom.sh", "installed": False},
    3: {"name": "Titan Network", "url": "https://titannet.gitbook.io/titan-network-en/galileo-testnet/titan-agent-installation-guide", "installer": "installers/titan.sh", "installed": False},
    4: {"name": "Farcaster", "url": "https://docs.farcaster.xyz/", "installer": "installers/farcaster.sh", "installed": False},
    5: {"name": "Nillion", "url": "https://docs.nillion.com/network", "installer": "installers/nillion.sh", "installed": False},
    6: {"name": "Initia", "url": "https://docs.initia.xyz/run-initia-node/running-initia-node", "installer": "installers/initia.sh", "installed": False},
    7: {"name": "eOracle", "url": "https://docs.eo.app/docs/operators/installation", "installer": "installers/eoracle.sh", "installed": False},
    8: {"name": "Spheron Network", "url": "https://docs.spheron.network/providers/setup-provider", "installer": "installers/spheron.sh", "installed": False},
}

# Глобальные переменные для данных прокси
proxy_server: str = ""
username: str = ""
password: str = ""

def get_current_ip() -> str:
    """Получение текущего IP-адреса"""
    try:
        response: requests.Response = requests.get("https://api.ipify.org?format=json", timeout=10)
        return response.json().get("ip")
    except Exception as e:
        print(f"Ошибка при получении IP-адреса: {e}")
        return None

def save_proxy_data() -> None:
    """Сохранение данных прокси в файл"""
    proxy_data: dict = \
    {
        "proxy_server": proxy_server,
        "username": username,
        "password": password
    }
    with open(PROXY_DATA_FILE, "w") as f:
        json.dump(proxy_data, f)

def load_proxy_data() -> bool:
    """Загрузка данных прокси из файла"""
    global proxy_server, username, password
    if os.path.exists(PROXY_DATA_FILE):
        with open(PROXY_DATA_FILE, "r") as f:
            proxy_data: dict = json.load(f)
            proxy_server = proxy_data.get("proxy_server", "")
            username = proxy_data.get("username", "")
            password = proxy_data.get("password", "")
        return True
    return False

def is_proxy_configured() -> bool:
    """Проверка, были ли данные прокси уже добавлены в /etc/environment"""
    if os.path.exists("/etc/environment"):
        with open("/etc/environment", "r") as f:
            content: str = f.read()
            return "http_proxy" in content and "https_proxy" in content
    return False

def setup_proxy() -> None:
    """Настройка прокси"""
    global proxy_server, username, password
    if load_proxy_data():
        print("Используются ранее сохранённые данные прокси.")
    else:
        proxy_server: str = input("Введите адрес прокси-сервера (например, http://proxy-server:port): ")
        username: str = input("Введите логин для прокси: ")
        password: str = input("Введите пароль для прокси: ")
        save_proxy_data()

    # Установка глобального прокси
    with open("/etc/environment", "a") as f:
        f.write(f"\nhttp_proxy=http://{username}:{password}@{proxy_server}\n")
        f.write(f"https_proxy=http://{username}:{password}@{proxy_server}\n")
        f.write("no_proxy=\"localhost,127.0.0.1,::1\"\n")
    print("Прокси успешно настроен.")

def validate_proxy(original_ip: str) -> None:
    """Проверка работы прокси"""
    while True:
        current_ip: str = get_current_ip()
        if current_ip and current_ip != original_ip:
            print(f"IP-адрес успешно изменён на: {current_ip}")
            break
        else:
            print("IP-адрес не изменился. Прокси не работает. Повторная попытка...")
            setup_proxy()

def reboot_system() -> None:
    """Перезагрузка системы"""
    print("Для применения настроек прокси требуется перезагрузка системы.")
    os.system("sudo reboot")

def display_menu() -> None:
    print("\n=== Доступные тестнет-проекты ===")
    for num, project in PROJECTS.items():
        status: str = "[✓]" if project["installed"] else "[ ]"
        print(f"{num}. {status} {project['name']} ({project['url']})")
    print("0. Выход")

def get_user_choice() -> int:
    while True:
        try:
            choice: int = int(input("Введите номер проекта для установки: "))
            if choice == 0:
                print("Выход из программы.")
                exit()
            elif choice in PROJECTS:
                return choice
            else:
                print("Неверный номер. Попробуйте снова.")
        except ValueError:
            print("Введите число.")

def run_installer(installer_path: str) -> bool:
    if not os.path.isfile(installer_path):
        print(f"Ошибка: Установщик не найден ({installer_path}).")
        return False

    print(f"Запуск установщика: {installer_path}")
    try:
        subprocess.run(["bash", installer_path], check=True)
        print("Установка завершена успешно!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Ошибка при установке: {e}")
        return False

def main() -> None:
    # Шаг 1: Проверка текущего IP-адреса
    print("Проверка текущего IP-адреса...")
    original_ip: str = get_current_ip()
    if not original_ip:
        print("Не удалось получить текущий IP-адрес. Проверьте подключение к интернету.")
        exit()
    print(f"Текущий IP-адрес: {original_ip}")

    # Шаг 2: Проверка наличия настроек прокси
    if is_proxy_configured():
        print("Прокси уже настроен. Пропускаем этап настройки прокси.")
    else:
        print("Настройка прокси...")
        setup_proxy()
        reboot_system()

    # Шаг 3: Проверка работы прокси
    print("Проверка работы прокси...")
    validate_proxy(original_ip)

    # Шаг 4: Предложение установки нод
    while True:
        display_menu()
        choice: int = get_user_choice()
        selected_project: dict = PROJECTS[choice]

        if not selected_project["installed"]:
            success: bool = run_installer(selected_project["installer"])
            if success:
                PROJECTS[choice]["installed"] = True
        else:
            print(f"{selected_project['name']} уже установлен.")

if __name__ == "__main__":
    main()
