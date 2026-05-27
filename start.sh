#!/bin/bash

# https://habr.com/ru/articles/1010942/

set -e

if [ -f .env ]
then
    source .env
fi

source utils.sh

CONTAINER_NAME="${CONTAINER_NAME:-mtproto-proxy}"
PORT="${PORT:-443}"

SERVER_IP="$(get-server-ip)"

if [ -z "$SECRET" ]
then

    FAKE_DOMAIN="${FAKE_DOMAIN:?set a domen like ozon.ru}"  # Фиксированный домен для Fake TLS

    echo "🚀 Запуск MTProto прокси с Fake TLS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "📌 Используем домен: ${BLUE}${FAKE_DOMAIN}${NC}"

    # Генерируем секрет для Fake TLS
    echo "🔑 Генерация Fake TLS секрета... "

    # Собираем секрет
    SECRET="$(get-secret $FAKE_DOMAIN)"
fi

echo -e "   Секрет: ${YELLOW}${SECRET}${NC}"
echo "   Длина: ${#SECRET} символов"

if docker ps -a | grep -q ${CONTAINER_NAME}
then
    # Останавливаем старый контейнер, если есть
    echo -n "🛑 Остановка старого контейнера... "
    docker stop ${CONTAINER_NAME} >/dev/null 2>&1
    docker rm ${CONTAINER_NAME} >/dev/null 2>&1
    echo -e "${GREEN}готово${NC}"
fi

# Проверяем, свободен ли порт 443
echo -n "🔍 Проверка порта ${PORT}... "
if ss -tuln | grep -q ":${PORT} "; then
    echo -e "${YELLOW}порт занят${NC}"
    exit 1
else
    echo -e "${GREEN}свободен${NC}"
fi


# Запускаем официальный прокси от Telegram
echo -n "📦 Запуск контейнера... "
docker run -d \
    --name ${CONTAINER_NAME} \
    --restart unless-stopped \
    -p ${PORT}:443 \
    -e SECRET="${SECRET}" \
    telegrammessenger/proxy > /dev/null 2>&1

# Проверяем результат
sleep 3
proxy="$(get-proxy)"
if docker ps | grep -q ${CONTAINER_NAME}; then
    echo -e "${GREEN}✅ УСПЕШНО${NC}"
    echo ""
    echo "📊 ИНФОРМАЦИЯ ДЛЯ ПОДКЛЮЧЕНИЯ:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 Сервер: ${SERVER_IP}"
    echo "🔌 Порт: ${PORT}"
    echo "🔑 Секрет: ${SECRET}"
    echo "🌐 Fake TLS домен: ${FAKE_DOMAIN}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔗 Ссылка для Telegram (нажмите для автоподключения):"
    echo -e "${GREEN}${proxy}${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Сохраняем конфигурацию
    cat > mtproto_config.txt << EOF
SERVER=${SERVER_IP}
PORT=${PORT}
SECRET=${SECRET}
DOMAIN=${FAKE_DOMAIN}
LINK=${proxy}
EOF
    echo "✅ Конфигурация сохранена в mtproto_config.txt"
    
    # Показываем последние логи
    echo ""
    echo "📋 Логи контейнера:"
    docker logs --tail 5 ${CONTAINER_NAME}
else
    echo -e "${RED}❌ ОШИБКА${NC}"
    docker logs ${CONTAINER_NAME}
fi


