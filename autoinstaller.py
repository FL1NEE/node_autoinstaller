import os
import subprocess
import requests

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

def get_current_ip():
    """Получение текущего IP-адреса"""
    try:
        response: str = requests.get("https://api.ipify.org?format=json", timeout=10)
        return response.json().get("ip")
    except Exception as e:
        print(f"Ошибка при получении IP-адреса: {e}")
        return None

def setup_proxy():
    """Настройка прокси"""
    proxy_server: str = input("Введите адрес прокси-сервера (например, http://proxy-server:port): ")
    username: str = input("Введите логин для прокси: ")
    password: str = input("Введите пароль для прокси: ")

    # Установка глобального прокси
    with open("/etc/environment", "a") as f:
        f.write(f"\nhttp_proxy=http://{username}:{password}@{proxy_server}\n")
        f.write(f"https_proxy=http://{username}:{password}@{proxy_server}\n")
        f.write("no_proxy=\"localhost,127.0.0.1,::1\"\n")
    os.system("source /etc/environment")
    print("Прокси успешно настроен.")

def validate_proxy(original_ip):
    """Проверка работы прокси"""
    while True:
        current_ip: str = get_current_ip()
        if str(current_ip) and str(current_ip) != str(original_ip):
            print(f"IP-адрес успешно изменён на: {current_ip}")
            break
        else:
            print("IP-адрес не изменился. Прокси не работает. Повторная попытка...")
            setup_proxy()

def display_menu():
    print("\n=== Доступные тестнет-проекты ===")
    for num, project in PROJECTS.items():
        status: str = "[✓]" if project["installed"] else "[ ]"
        print(f"{num}. {status} {project['name']} ({project['url']})")
    print("0. Выход")

def get_user_choice():
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

def run_installer(installer_path):
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

def main():
    # Шаг 1: Проверка текущего IP-адреса
    print("Проверка текущего IP-адреса...")
    original_ip: str = get_current_ip()
    if not original_ip:
        print("Не удалось получить текущий IP-адрес. Проверьте подключение к интернету.")
        exit()
    print(f"Текущий IP-адрес: {original_ip}")

    # Шаг 2: Настройка прокси
    print("Настройка прокси...")
    setup_proxy()

    # Шаг 3: Проверка работы прокси
    print("Проверка работы прокси...")
    validate_proxy(original_ip)

    # Шаг 4: Предложение установки нод
    while True:
        display_menu()
        choice: str = get_user_choice()
        selected_project: str = PROJECTS[choice]

        if not selected_project["installed"]:
            success: str = run_installer(selected_project["installer"])
            if success:
                PROJECTS[choice]["installed"] = True
        else:
            print(f"{selected_project['name']} уже установлен.")

if __name__ == "__main__":
    main()
