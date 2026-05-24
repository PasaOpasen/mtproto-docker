#!/bin/bash

set -e

if [ -f .env ]
then
    source .env
fi

source utils.sh

PAUSE_HOURS="${PAUSE_HOURS:-36}"
FAKE_DOMAIN="${FAKE_DOMAIN:?set a domen like yar1.ru}" 

s1="$(get-secret $FAKE_DOMAIN)"
s2="$(get-secret $FAKE_DOMAIN)"
s3="$(get-secret $FAKE_DOMAIN)"

while true
do
    export SECRET="$s1"
    bash start.sh

    # to update variables
    if [ -f .env ]
    then
        source .env
    fi   
    PAUSE="$((PAUSE_HOURS * 60 * 60))"

    s1="$s2"
    s2="$s3"
    s3="$(get-secret $FAKE_DOMAIN)"

    if [ -n "$BOTTOKEN" ] && [ -n "$CHATID" ]
    then
        curl -X POST "https://api.telegram.org/bot$BOTTOKEN/sendMessage" \
            -d "chat_id=$CHATID" \
            --data-urlencode "text=Current proxy:
$(get-proxy $SECRET)

Next proxies:
 $(get-proxy $s1)

 $(get-proxy $s2)
 
 $(get-proxy $s3)"
    fi

    echo
    echo
    echo "Sleep for $PAUSE seconds (${PAUSE_HOURS} hours)..."
    sleep $PAUSE
done

