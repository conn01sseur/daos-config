#!/bin/bash

# Подключение к VPN с помощью outline-cli
VPN_COMMAND="sudo go run github.com/Jigsaw-Code/outline-sdk/x/examples/outline-cli@latest -transport 'ss://Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNTpsbU9Gajk1U21GUDloYVlldzF4TW5F@46.17.105.226:1069/?outline=1'"

# Выполнение команды
if $VPN_COMMAND; then
    notify-send "VPN" "Успешное подключение к VPN"
else
    notify-send "VPN" "Не удалось подключиться к VPN"
fi
