# mtproto-docker

Скрипты для поднятия Mtproto на своём сервере. 

Зависимости:
```sh
dnf install screen make curl + docker
```

Максимальный `.env`:
```sh
IMPLEMENTAION="<proxy implementation: official (official Telegram image) or mtg (nineseconds/mtg:2)>; official by default"

FAKE_DOMAIN="<domain like yandex.ru, ozon.ru>"  # FAKE TLS DOMAIN

CONTAINER_NAME=mtproto-proxy
PORT=443
SERVER_IP="<auto if empty>"

SECRET="<generated from FAKE_DOMAIN if empty>"

PAUSE_HOURS="<update proxy after this pause>"

BOTTOKEN="<telegram bot token for notifications>"
CHATID="<telegram chat id for notifications>"
```

Запуск screen-сессии, в которой прокси поднимается каждые несколько часов с отправкой уведомлений в телегу: `make up`

Примечания: 
* переподнимать прокси приходится затем, чтобы поменять ключ, так как ебучие провайдеры могут за несколько дней разпознать конкретный прокси и заблочить; поэтому в уведомлении отправляется не только текущий ключ, но и несколько следующих (чтобы иметь ссылку сильно заранее)  
