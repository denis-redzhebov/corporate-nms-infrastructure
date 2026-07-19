#!/bin/bash
# Инсталация на Nextcloud чрез Snap пакет (Ubuntu Server, 192.168.10.10)
# Snap осигурява изолирана среда с всички зависимости (уеб сървър, БД, PHP)

sudo snap install nextcloud

# Освобождаване на порт 80 (конфликт с Apache2, ако е активен)
sudo systemctl stop apache2
sudo systemctl disable apache2
sudo snap restart nextcloud

# Активиране на HTTPS със self-signed сертификат (затворена локална мрежа)
sudo nextcloud.enable-https self-signed
