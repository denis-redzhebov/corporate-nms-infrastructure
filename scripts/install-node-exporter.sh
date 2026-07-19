#!/bin/bash
# Инсталация на Prometheus Node Exporter директно на хост машината
# Предоставя Linux системни метрики на порт 9100

sudo apt update
sudo apt install prometheus-node-exporter -y
