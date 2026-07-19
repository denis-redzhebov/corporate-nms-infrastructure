[Български](README.md) · [English](README.en.md)

# Corporate Network Infrastructure Management with Remote Offices

Practical implementation of a network monitoring system, centralized logging,
IP address management, and a private cloud service for a simulated corporate
network with remote offices, connected through an encrypted VPN.

*Developed as a Bachelor's thesis project (Technical University of Varna, 2026).*

[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?logo=ubuntu&logoColor=white)](#)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=fff)](#)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?logo=prometheus&logoColor=white)](#)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)](#)
[![Nextcloud](https://img.shields.io/badge/Nextcloud-0082C9?style=flat&logo=nextcloud&logoColor=white)](#)
[![MikroTik](https://img.shields.io/badge/MikroTik-293239?style=flat&logo=mikrotik&logoColor=white)](#)

---

## Table of contents
- [About the project](#about-the-project)
- [Ports and services](#ports-and-services)
- [Network topology](#network-topology)
- [1. Centralized Syslog server](#1-centralized-syslog-server)
- [2. IP Address Management system (NetBox)](#2-ip-address-management-system-netbox)
- [3. Network monitoring system (Netdata, Prometheus, Grafana)](#3-network-monitoring-system-netdata-prometheus-grafana)
- [4. Private cloud service (Nextcloud)](#4-private-cloud-service-nextcloud)
- [Full documentation](#full-documentation)

---

## About the project

This project is part of a joint team effort simulating a corporate network
with a headquarters and two remote branches (Hub-and-Spoke model), connected
through an encrypted VPN (ZeroTier). The overall infrastructure was built in
a virtual environment using GNS3 and MikroTik RouterOS routers.

**My individual contribution** covers the Linux-based branch office, including:
- A centralized system log collection service (Syslog) with an automated critical event response module
- An IP Address Management / IPAM system (NetBox)
- A real-time network monitoring system (Netdata, Prometheus, Grafana)
- A private cloud service (Nextcloud) integrated with Active Directory and a Windows file share

## Ports and services

| Service | Port | Role |
|---|---|---|
| Nextcloud | 443 (HTTPS) | Private cloud service |
| NetBox | 8000 | IPAM / Source of Truth |
| Prometheus | 9090 | Telemetry collection |
| Grafana | 3000 | Visualization |
| Netdata | 19999 | Real-time monitoring |
| Node Exporter | 9100 | Linux metrics |
| Windows Exporter | 9182 | Windows metrics |
| Syslog (UDP) | 514 | Centralized logging |

## Network topology

<img src="network-topology/topology-diagram.png" width="750">

A headquarters (Windows AD) and two remote branches (Linux infrastructure —
my part of the project, and a Security infrastructure branch), connected
through a VPN overlay network.

---

## 1. Centralized Syslog server

Built with rsyslog on Ubuntu Server — accepts UDP messages on port 514
from the MikroTik routers. See [`configs/rsyslog/rsyslog.conf`](configs/rsyslog/rsyslog.conf).

Extended with two automated bash scripts:
- [`scripts/alert_monitor.sh`](scripts/alert_monitor.sh) — filters critical
  events (failed login attempts) in real time, logs them to a separate
  archive, broadcasts an alert to all active admin sessions, and simulates
  sending an email notification
- [`scripts/ad-watchdog.sh`](scripts/ad-watchdog.sh) — monitors the
  availability of the Active Directory server and automatically
  enables/disables the LDAP integration in Nextcloud when the connection drops

<img src="screenshots/syslog-critical-alert.png" width="650">

*Automatic broadcast alert triggered by a detected failed login attempt*

## 2. IP Address Management system (NetBox)

A centralized "source of truth" for the network address space, deployed via
the Docker version of NetBox. See
[`configs/netbox/docker-compose.override.yml`](configs/netbox/docker-compose.override.yml).

Documents the three sites in the topology, their network prefixes, device
IP addresses, and network services. The platform actively prevents
duplicate IP address entries:

<img src="screenshots/netbox-duplicate-ip-prevention.png" width="650">

*NetBox blocking an attempt to register an already-used IP address*

<details>
<summary>More NetBox screenshots</summary>
<br>

<img src="screenshots/netbox-sites.png" width="650">

*Defined sites in the topology*

<img src="screenshots/netbox-ip-addresses.png" width="650">

*IP address registry*

<img src="screenshots/netbox-prefixes.png" width="650">

*Network prefixes by site*

</details>

## 3. Network monitoring system (Netdata, Prometheus, Grafana)

A three-layer real-time monitoring architecture:

- **Netdata** — high-resolution (1-second) monitoring of system resources,
  available on port 19999. See
  [`scripts/deploy-netdata.sh`](scripts/deploy-netdata.sh).
- **Prometheus** — centralized telemetry collection via a pull model from
  the Linux server (Node Exporter, port 9100) and the remote Windows server
  (Windows Exporter, port 9182). See
  [`configs/prometheus/prometheus.yml`](configs/prometheus/prometheus.yml) and
  [`scripts/deploy-prometheus.sh`](scripts/deploy-prometheus.sh).
- **Grafana** — visualization through pre-built dashboard templates (Node
  Exporter Full - ID 1860, Windows Exporter - ID 14510). See
  [`scripts/deploy-grafana.sh`](scripts/deploy-grafana.sh).

<img src="screenshots/grafana-cpu-load-test.png" width="650">

*Artificial load test — Grafana capturing the change in real time*

<table>
<tr>
<td><img src="screenshots/grafana-linux-dashboard.png" width="400"></td>
<td><img src="screenshots/grafana-windows-dashboard.png" width="400"></td>
</tr>
<tr>
<td align="center"><i>Linux server</i></td>
<td align="center"><i>Windows server</i></td>
</tr>
</table>

<details>
<summary>More monitoring stack screenshots</summary>
<br>

<img src="screenshots/netdata-realtime-dashboard.png" width="650">

*Netdata - real-time server resource monitoring*

<img src="screenshots/prometheus-targets-status.png" width="650">

*Prometheus - monitored targets status (UP)*

</details>

## 4. Private cloud service (Nextcloud)

Deployed via a Snap package with HTTPS (self-signed certificate for a
closed lab network). See [`scripts/install-nextcloud.sh`](scripts/install-nextcloud.sh).

Integrated with:
- **Active Directory** over LDAPS (port 636) — centralized authentication
  using users' domain credentials. See
  [`configs/nextcloud/ldap-settings.md`](configs/nextcloud/ldap-settings.md).
- **Windows file share** over SMB/CIFS, mounted as External Storage. See
  [`configs/nextcloud/cifs-mount-example.sh`](configs/nextcloud/cifs-mount-example.sh).

Access is distributed by department through Active Directory groups —
each user sees only their department's resources:

<img src="screenshots/nextcloud-hr-limited-view.png" width="650">

*Restricted folder view through an HR department user profile*

<details>
<summary>More Nextcloud screenshots</summary>
<br>

<img src="screenshots/nextcloud-https-interface.png" width="650">

*Landing interface over a secured HTTPS connection*

<img src="screenshots/nextcloud-ldap-config.png" width="650">

*Configured LDAP connection to Active Directory*

<img src="screenshots/nextcloud-ad-users-synced.png" width="650">

*Automatically synced users and groups*

<img src="screenshots/nextcloud-external-storage.png" width="650">

*Windows file share mounted as External Storage*

<img src="screenshots/nextcloud-department-permissions.png" width="650">

*Department-based access permissions*

</details>

---

## Full documentation

The full text of the thesis, including the theoretical background and a
detailed description of the implementation (in Bulgarian), is available here:
[`docs/Дипломна_Работа.pdf`](docs/Дипломна_Работа.pdf)

---
