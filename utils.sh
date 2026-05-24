
# Цвета для красивого вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function get-secret {
    if [ -z "$1" ]
    then
        echo "domain is not specified"
        return 1
    fi

    local DOMAIN_HEX=$(echo -n $1 | xxd -ps | tr -d '\n')

    # Дополняем случайными символами до 30 символов
    local DOMAIN_LEN=${#DOMAIN_HEX}
    local NEEDED=$((30 - DOMAIN_LEN))
    local RANDOM_HEX=$(openssl rand -hex 15 | cut -c1-$NEEDED)

    # Собираем секрет
    echo -n "ee${RANDOM_HEX}${DOMAIN_HEX}"
}


function get-server-ip {
    if [ -n "$SERVER_IP" ]
    then
        echo -n "$SERVER_IP"
    else
        curl -s ifconfig.me
    fi
}

function get-proxy {
    if [ -z "$PORT" ]
    then
        echo "PORT is not set"
        return 1
    fi
    local SERVER_IP="$(get-server-ip)"
    echo -n "tg://proxy?server=${SERVER_IP}&port=${PORT}&secret=${1:-$SECRET}"
}

