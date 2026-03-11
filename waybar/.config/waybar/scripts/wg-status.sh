#!/bin/bash
if ip link show stern up > /dev/null 2>&1; then
    echo '{"text": "tun", "class": "connected"}'
else
    echo '{"text": "", "class": "disconnected"}'
fi

