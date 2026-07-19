#!/bin/bash
SERVER="192.168.20.10"
STATE_FILE="/usr/local/bin/ad_is_up"

if ping -c 2 -W 2 $SERVER > /dev/null; then
    if [ ! -f "$STATE_FILE" ]; then
        /snap/bin/nextcloud.occ app:enable user_ldap
        touch "$STATE_FILE"
    fi
    /bin/mount -a
else
    if [ -f "$STATE_FILE" ]; then
        /snap/bin/nextcloud.occ app:disable user_ldap
        /bin/umount -l /media/windows_share 2>/dev/null
        rm "$STATE_FILE"
    fi
fi
