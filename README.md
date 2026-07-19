[Български](README.md) · [English](README.en.md)

# Мрежово управление на корпоративна инфраструктура с отдалечени офиси

Практическа реализация на система за мрежово наблюдение, централизирано логване, 
IP адресно управление и частна облачна услуга за симулирана корпоративна мрежа 
с отдалечени офиси, свързани чрез криптирана VPN мрежа.

*Проектът е разработен като бакалавърска дипломна работа (ТУ - Варна, 2026).*

[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?logo=ubuntu&logoColor=white)](#)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=fff)](#)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?logo=prometheus&logoColor=white)](#)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)](#)
[![Nextcloud](https://img.shields.io/badge/Nextcloud-0082C9?style=flat&logo=nextcloud&logoColor=white)](#)
[![MikroTik](https://img.shields.io/badge/MikroTik-293239?style=flat&logo=mikrotik&logoColor=white)](#)

---

## Съдържание
- [За проекта](#за-проекта)
- [Портове и услуги](#портове-и-услуги)
- [Мрежова топология](#мрежова-топология)
- [1. Централизиран Syslog сървър](#1-централизиран-syslog-сървър)
- [2. Система за IP адресно управление (NetBox)](#2-система-за-ip-адресно-управление-netbox)
- [3. Система за мрежово наблюдение (Netdata, Prometheus, Grafana)](#3-система-за-мрежово-наблюдение-netdata-prometheus-grafana)
- [4. Частна облачна услуга (Nextcloud)](#4-частна-облачна-услуга-nextcloud)
- [Пълна документация](#пълна-документация)

---

## За проекта

Проектът е част от съвместна екипна разработка, симулираща корпоративна мрежа
с централен офис и два отдалечени клона (модел Hub-and-Spoke), свързани чрез
криптирана VPN мрежа (ZeroTier). Общата инфраструктура е изградена във
виртуална среда чрез GNS3 и MikroTik RouterOS маршрутизатори.

**Моят самостоятелен принос** обхваща периферния Linux-базиран офис:
- Централизирана система за събиране на системни съобщения (Syslog) с автоматизиран модул за реакция при критични събития
- Система за управление на IP адресното пространство / IPAM (NetBox)
- Система за мрежово наблюдение в реално време (Netdata, Prometheus, Grafana)
- Частна облачна услуга (Nextcloud) с интеграция към Active Directory и Windows файлово хранилище

## Портове и услуги

| Услуга | Порт | Роля |
|---|---|---|
| Nextcloud | 443 (HTTPS) | Частна облачна услуга |
| NetBox | 8000 | IPAM / Source of Truth |
| Prometheus | 9090 | Събиране на телеметрия |
| Grafana | 3000 | Визуализация |
| Netdata | 19999 | Real-time мониторинг |
| Node Exporter | 9100 | Linux метрики |
| Windows Exporter | 9182 | Windows метрики |
| Syslog (UDP) | 514 | Централизирано логване |

## Мрежова топология

<img src="network-topology/topology-diagram.png" width="750">

Централен офис (Windows AD) и два отдалечени клона (Linux инфраструктура —
моята част от проекта, и Security инфраструктура), свързани чрез VPN Overlay мрежа.

---

## 1. Централизиран Syslog сървър

Изграден чрез rsyslog на Ubuntu Server — приема UDP съобщения на порт 514
от MikroTik маршрутизаторите. Виж [`configs/rsyslog/rsyslog.conf`](configs/rsyslog/rsyslog.conf).

Допълнен с два автоматизирани bash скрипта:
- [`scripts/alert_monitor.sh`](scripts/alert_monitor.sh) — филтрира критични
  събития (неуспешни опити за вход) в реално време, записва ги в отделен
  архив, изпраща broadcast известие до всички активни администраторски
  сесии и симулира изпращане на email
- [`scripts/ad-watchdog.sh`](scripts/ad-watchdog.sh) — следи наличността
  на Active Directory сървъра и автоматично включва/изключва LDAP
  интеграцията в Nextcloud при прекъсване на връзката

<img src="screenshots/syslog-critical-alert.png" width="650">

*Автоматична broadcast аларма при засечен неуспешен опит за вход*

## 2. Система за IP адресно управление (NetBox)

Централизиран "източник на истината" (Source of Truth) за мрежовото
адресно пространство, изграден чрез Docker версията на NetBox. Виж
[`configs/netbox/docker-compose.override.yml`](configs/netbox/docker-compose.override.yml).

Документирани са трите локации (Sites), мрежовите префикси, IP адресите
на устройствата и мрежовите услуги. Платформата активно предотвратява
дублиране на IP адреси в адресното пространство:

<img src="screenshots/netbox-duplicate-ip-prevention.png" width="650">

*NetBox блокира опит за въвеждане на вече използван IP адрес*

<details>
<summary>Още скрийншотове от NetBox</summary>
<br>

<img src="screenshots/netbox-sites.png" width="650">

*Дефинирани локации (Sites) в топологията*

<img src="screenshots/netbox-ip-addresses.png" width="650">

*Регистър на IP адресите*

<img src="screenshots/netbox-prefixes.png" width="650">

*Мрежови префикси по локация*

</details>

## 3. Система за мрежово наблюдение (Netdata, Prometheus, Grafana)

Трислойна архитектура за мониторинг в реално време:

- **Netdata** — мониторинг с висока разделителна способност (1 сек.) на
  системните ресурси, достъпен на порт 19999. Виж
  [`scripts/deploy-netdata.sh`](scripts/deploy-netdata.sh).
- **Prometheus** — централизирано събиране на телеметрия чрез pull модел
  от Linux сървъра (Node Exporter, порт 9100) и отдалечения Windows сървър
  (Windows Exporter, порт 9182). Виж
  [`configs/prometheus/prometheus.yml`](configs/prometheus/prometheus.yml) и
  [`scripts/deploy-prometheus.sh`](scripts/deploy-prometheus.sh).
- **Grafana** — визуализация чрез готови dashboard шаблони (Node Exporter
  Full - ID 1860, Windows Exporter - ID 14510). Виж
  [`scripts/deploy-grafana.sh`](scripts/deploy-grafana.sh).

<img src="screenshots/grafana-cpu-load-test.png" width="650">

*Тест с изкуствено генерирано натоварване — Grafana отчита промяната в реално време*

<table>
<tr>
<td><img src="screenshots/grafana-linux-dashboard.png" width="400"></td>
<td><img src="screenshots/grafana-windows-dashboard.png" width="400"></td>
</tr>
<tr>
<td align="center"><i>Linux сървър</i></td>
<td align="center"><i>Windows сървър</i></td>
</tr>
</table>

<details>
<summary>Още скрийншотове от мониторинг стека</summary>
<br>

<img src="screenshots/netdata-realtime-dashboard.png" width="650">

*Netdata - мониторинг на сървърните ресурси в реално време*

<img src="screenshots/prometheus-targets-status.png" width="650">

*Prometheus - статус на наблюдаваните цели (UP)*

</details>

## 4. Частна облачна услуга (Nextcloud)

Внедрена чрез Snap пакет с HTTPS (self-signed сертификат за затворена
лабораторна мрежа). Виж [`scripts/install-nextcloud.sh`](scripts/install-nextcloud.sh).

Интегрирана с:
- **Active Directory** през LDAPS (порт 636) — централизирано удостоверяване
  на потребителите с техните домейнски имена и пароли. Виж
  [`configs/nextcloud/ldap-settings.md`](configs/nextcloud/ldap-settings.md).
- **Windows файлово хранилище** през SMB/CIFS, монтирано като External
  Storage. Виж [`configs/nextcloud/cifs-mount-example.sh`](configs/nextcloud/cifs-mount-example.sh).

Достъпът е разпределен по отдели чрез Active Directory групи — всеки
потребител вижда само ресурсите на своя отдел:

<img src="screenshots/nextcloud-hr-limited-view.png" width="650">

*Ограничен изглед на файловата структура през потребителски профил на HR отдел*

<details>
<summary>Още скрийншотове от Nextcloud</summary>
<br>

<img src="screenshots/nextcloud-https-interface.png" width="650">

*Начален интерфейс през защитена HTTPS връзка*

<img src="screenshots/nextcloud-ldap-config.png" width="650">

*Конфигурирана LDAP връзка към Active Directory*

<img src="screenshots/nextcloud-ad-users-synced.png" width="650">

*Автоматично синхронизирани потребители и групи*

<img src="screenshots/nextcloud-external-storage.png" width="650">

*Windows файлово хранилище, монтирано като External Storage*

<img src="screenshots/nextcloud-department-permissions.png" width="650">

*Разпределение на правата за достъп по отдели*

</details>

---

## Пълна документация

Пълният текст на дипломната работа, включващ теоретичната част и
детайлно описание на реализацията, е достъпен тук:
[`docs/Дипломна_Работа.pdf`](docs/Дипломна_Работа.pdf)

---
