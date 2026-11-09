#!/usr/bin/env bash

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
    echo "Usage: $0 <app-url>" >&2
    exit 1
fi

URL="${1%/}/health"

for attempt in {1..5}; do
    STATUS=$(curl \
        --silent \
        --output /dev/null \
        --write-out '%{http_code}' \
        --max-time 5 \
        "$URL" 2>/dev/null)

    STATUS="${STATUS:-000}"

    printf '[%s] Attempt %s/5 - HTTP %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$attempt" "$STATUS"

    if [ "$STATUS" = "200" ]; then
        exit 0
    fi

    if [ "$attempt" -lt 5 ]; then
        sleep 3
    fi
done

exit 1
