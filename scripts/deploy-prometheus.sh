#!/bin/bash
# Стартиране на Prometheus чрез Docker
# Монтира локалната конфигурация в контейнера

sudo docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v /home/denis/prometheus_config/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus
