

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

