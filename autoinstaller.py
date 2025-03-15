# -*- coding: utf-8 -*-
import os
import subprocess
import requests
import json

# Путь к файлу для хранения данных прокси
PROXY_DATA_FILE: str = "proxy_data.json"

# Базовые URL для GitHub API и raw-файлов
GITHUB_API_URL: str = "https://api.github.com/repos/FL1NEE/node_autoinstaller/contents/installers"
RAW_BASE_URL: str = "https://raw.githubusercontent.com/FL1NEE/node_autoinstaller/main/"

# Класс для хранения данных прокси
class ProxyData:
    def __init__(self):
        self.proxy_server: str = ""
        self.username: str = ""
        self.password: str = ""

proxy_data = ProxyData()

def get_current_ip() -> str:
    """Получение текущего IP-адреса"""
    try:
        response = requests.get("https://api.ipify.org?format=json", timeout=10)
        return response.json().get("ip")
    except Exception as e:
        print(f"Ошибка при получении IP-адреса: {e}")
        return None

def save_proxy_data() -> None:
    """Сохранение данных прокси в файл"""
    proxy_data_dict = {
        "proxy_server": proxy_data.proxy_server,
        "username": proxy_data.username,
        "password": proxy_data.password,
    }
    with open(PROXY_DATA_FILE, "w") as f:
        json.dump(proxy_data_dict, f)

def load_proxy_data() -> bool:
    """Загрузка данных прокси из файла"""
    if os.path.exists(PROXY_DATA_FILE):
        with open(PROXY_DATA_FILE, "r") as f:
            proxy_data_dict = json.load(f)
            proxy_data.proxy_server = proxy_data_dict.get("proxy_server", "")
            proxy_data.username = proxy_data_dict.get("username", "")
            proxy_data.password = proxy_data_dict.get("password", "")
        return True
    return False

def is_proxy_configured() -> bool:
    """Проверка, были ли данные прокси уже добавлены в /etc/environment"""
    if os.path.exists("/etc/environment"):
        with open("/etc/environment", "r") as f:
            content = f.read()
            return "http_proxy" in content and "https_proxy" in content
    return False

def setup_proxy() -> None:
    """Настройка прокси"""
    if load_proxy_data():
        print("Используются ранее сохранённые данные прокси.")
    else:
        proxy_data.proxy_server = input("Введите адрес прокси-сервера (например, proxy-server:port): ")
        proxy_data.username = input("Введите логин для прокси: ")
        proxy_data.password = input("Введите пароль для прокси: ")
        save_proxy_data()

    # Установка глобального прокси
    with open("/etc/environment", "a") as f:
        f.write(f"\nhttp_proxy=http://{proxy_data.username}:{proxy_data.password}@{proxy_data.proxy_server}\n")
        f.write(f"https_proxy=http://{proxy_data.username}:{proxy_data.password}@{proxy_data.proxy_server}\n")
        f.write("no_proxy=\"localhost,127.0.0.1,::1\"\n")
    print("Прокси успешно настроен.")

def check_proxy_availability(proxy_url: str) -> bool:
    """Проверка доступности прокси"""
    try:
        response = requests.get("https://ipv4.jsonip.com/", proxies={"http": proxy_url, "https": proxy_url}, timeout=20)
        if response.status_code == 200:
            print(f"Прокси работает. Полученный IP: {response.json()['ip']}")
            return True
        else:
            print("Прокси не работает. Статус код:", response.status_code)
            return False
    except Exception as e:
        print(f"Ошибка при проверке прокси: {e}")
        return False

def validate_proxy(original_ip: str) -> None:
    """Проверка работы прокси"""
    max_attempts = 3
    attempt = 0

    while attempt < max_attempts:
        current_ip = get_current_ip()
        proxy_url = f"http://{proxy_data.username}:{proxy_data.password}@{proxy_data.proxy_server}"

        if check_proxy_availability(proxy_url):
            print("Прокси успешно настроен и работает.")
            return
        else:
            print("Прокси не работает.")
            attempt += 1
            if attempt < max_attempts:
                print(f"Попытка {attempt}/{max_attempts}. Повторная настройка прокси...")
                setup_proxy()
            else:
                print("Прокси не удалось настроить после нескольких попыток.")
                exit(1)

def reboot_system() -> None:
    """Перезагрузка системы"""
    print("Для применения настроек прокси требуется перезагрузка системы.")
    confirm = input("Хотите перезагрузить систему сейчас? (y/n): ").strip().lower()
    if confirm == "y":
        print("Перезагрузка системы...")
        os.system("sudo reboot")
    else:
        print("Перезагрузите систему вручную для применения изменений.")

def fetch_projects() -> dict:
    """Получение списка проектов из репозитория"""
    try:
        response = requests.get(GITHUB_API_URL)
        response.raise_for_status()
        files = response.json()
        projects = {}
        for idx, file in enumerate(files, start=1):
            if file["type"] == "file" and file["name"].endswith(".sh"):
                project_name = file["name"].replace(".sh", "").capitalize()
                projects[idx] = {
                    "name": project_name,
                    "url": RAW_BASE_URL + file["path"],
                    "installed": False,
                }
        return projects
    except Exception as e:
        print(f"Ошибка при получении списка проектов: {e}")
        return {}

def display_menu(projects: dict) -> None:
    print("\n=== Доступные тестнет-проекты ===")
    for num, project in projects.items():
        status = "[✓]" if project["installed"] else "[ ]"
        print(f"{num}. {status} {project['name']}")
    print("0. Выход")

def get_user_choice(projects: dict) -> int:
    while True:
        try:
            choice = int(input("Введите номер проекта для установки: "))
            if choice == 0:
                print("Выход из программы.")
                exit()
            elif choice in projects:
                return choice
            else:
                print("Неверный номер. Попробуйте снова.")
        except ValueError:
            print("Введите число.")

def run_installer(installer_url: str) -> bool:
    installer_name = installer_url.split("/")[-1]
    try:
        print(f"Скачивание установщика: {installer_url}")
        response = requests.get(installer_url)
        response.raise_for_status()
        with open(installer_name, "wb") as f:
            f.write(response.content)
        print(f"Установщик '{installer_name}' успешно скачан.")
    except Exception as e:
        print(f"Ошибка при скачивании установщика: {e}")
        return False

    print(f"Запуск установщика: {installer_name}")
    try:
        subprocess.run(["bash", installer_name], check=True)
        print("Установка завершена успешно!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Ошибка при установке: {e}")
        return False

def main() -> None:
    # Шаг 1: Проверка текущего IP-адреса
    print("Проверка текущего IP-адреса...")
    original_ip = get_current_ip()
    if not original_ip:
        print("Не удалось получить текущий IP-адрес. Проверьте подключение к интернету.")
        exit()
    print(f"Текущий IP-адрес: {original_ip}")

    # Шаг 2: Проверка наличия настроек прокси
    if is_proxy_configured():
        print("Прокси уже настроен.")
        proxy_url = f"http://{proxy_data.username}:{proxy_data.password}@{proxy_data.proxy_server}"
        if not check_proxy_availability(proxy_url):
            print("Прокси не работает. Проверяем работу прокси...")
            validate_proxy(original_ip)
    else:
        print("Настройка прокси...")
        setup_proxy()
        reboot_system()

    # Шаг 3: Получение списка проектов
    projects = fetch_projects()
    if not projects:
        print("Не удалось получить список проектов. Завершение программы.")
        exit()

    # Шаг 4: Предложение установки нод
    while True:
        display_menu(projects)
        choice = get_user_choice(projects)
        selected_project = projects[choice]

        if not selected_project["installed"]:
            success = run_installer(selected_project["url"])
            if success:
                projects[choice]["installed"] = True
        else:
            print(f"{selected_project['name']} уже установлен.")

if __name__ == "__main__":
    main()
