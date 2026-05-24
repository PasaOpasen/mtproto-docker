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
FAKE_DOMAIN="${FAKE_DOMAIN:?set a domen like yar1.ru}"  # Фиксированный домен для Fake TLS

SERVER_IP="${SERVER_IP}"
if [ -z "${SERVER_IP}" ]
then
    SERVER_IP=$(curl -s ifconfig.me)
fi

# Цвета для красивого вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'


echo "🚀 Запуск MTProto прокси с Fake TLS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "📌 Используем домен: ${BLUE}${FAKE_DOMAIN}${NC}"

# Генерируем секрет для Fake TLS
echo "🔑 Генерация Fake TLS секрета... "

# Собираем секрет
SECRET="$(get-secret $FAKE_DOMAIN)"
echo -e "   Секрет: ${YELLOW}${SECRET}${NC}"
echo "   Длина: ${#SECRET} символов"

# Останавливаем старый контейнер, если есть
echo -n "🛑 Остановка старого контейнера... "
docker stop ${CONTAINER_NAME} >/dev/null 2>&1
docker rm ${CONTAINER_NAME} >/dev/null 2>&1
echo -e "${GREEN}готово${NC}"

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
proxy="tg://proxy?server=${SERVER_IP}&port=${PORT}&secret=${SECRET}"
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

if [ -n "$BOTTOKEN" ] && [ -n "$CHATID" ]
then
    curl -X POST "https://api.telegram.org/bot$BOTTOKEN/sendMessage" \
        -d "chat_id=$CHATID" \
        -d "text=$proxy"
fi
