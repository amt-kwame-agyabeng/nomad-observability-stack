# Architecture Guide

## Overview

This project deploys a monitoring and centralized logging stack using HashiCorp Nomad and Docker. It demonstrates two observability pipelines: metrics collection and log collection.

## Components

| Component | Responsibility |
|---|---|
| Nomad | Schedules and manages service workloads |
| Docker | Runs container workloads through the Nomad Docker task driver |
| Nginx | Sample web service and source of HTTP access logs |
| Node Exporter | Exposes host-level metrics |
| Prometheus | Scrapes and stores metrics as time series |
| Grafana Alloy | Discovers Docker containers, collects logs, and forwards them |
| Loki | Receives and serves log streams |
| Grafana | Displays metrics dashboards and provides log exploration |

## Metrics pipeline

1. Node Exporter exposes host metrics on port `9100`.
2. Prometheus scrapes Node Exporter at the configured interval.
3. Prometheus stores the resulting time series.
4. Grafana queries Prometheus and renders dashboards.

**Flow:** `Node Exporter → Prometheus → Grafana`

The lab used a 15-second scrape interval and targets for Node Exporter (`172.18.49.163:9100`) and Prometheus itself (`172.18.49.163:9090`).

## Logging pipeline

1. Nginx and the monitoring services run as Docker containers managed by Nomad.
2. Grafana Alloy discovers Docker containers through `/var/run/docker.sock`.
3. Alloy collects container logs and attaches labels, including the container name and `job="docker"`.
4. Alloy sends log entries to Loki's push API.
5. Grafana queries Loki through Explore.

**Flow:** `Docker containers → Grafana Alloy → Loki → Grafana`

The Loki push endpoint used in the lab was `http://172.18.49.163:3100/loki/api/v1/push`.

## Endpoints used in the lab

The WSL host IP observed during implementation was `172.18.49.163`. WSL addresses can change after restart; update configuration files if the address changes.

| Service | Endpoint |
|---|---|
| Nomad UI | `http://127.0.0.1:4646` |
| Nginx | `http://172.18.49.163:8080` |
| Node Exporter | `http://172.18.49.163:9100/metrics` |
| Prometheus | `http://172.18.49.163:9090` |
| Loki readiness | `http://172.18.49.163:3100/ready` |
| Grafana | `http://172.18.49.163:3000` |
| Grafana Alloy UI | `http://172.18.49.163:12345` |

## Design notes and limitations

- Nomad ran in development mode. This is for learning and testing, not production; its state is ephemeral.
- Alloy used host networking because the local Nomad client did not have the required CNI bridge plugin available.
- Alloy mounts the Docker socket. Access to it can provide extensive control over the Docker host and must be treated as highly privileged.
- Node Exporter reported duplicate filesystem metric errors for some WSL mount information. This was not resolved as part of the logging integration.
- This is a local lab demonstration, not a hardened or highly available production architecture.
