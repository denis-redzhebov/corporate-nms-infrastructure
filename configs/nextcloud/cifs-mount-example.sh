#!/bin/bash
# Монтиране на отдалечено Windows файлово хранилище (SMB/CIFS)
# ВНИМАНИЕ: замени YOUR_PASSWORD с реалната парола преди изпълнение
# Никога не commit-вай тази команда с истинска парола в системата за контрол на версии

sudo mount -t cifs //192.168.20.10/Office_Data /media/windows_share \
  -o username=Administrator,password=YOUR_PASSWORD,vers=3.0,dir_mode=0777,file_mode=0777
