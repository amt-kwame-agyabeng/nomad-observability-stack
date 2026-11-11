# Architecture Guide

## 1. Overview

This project deploys a monitoring and centralized logging stack using HashiCorp Nomad and Docker. It demonstrates two observability pipelines:

- **Metrics collection:** Collects host-level metrics and Nomad workload statistics, stores them in Prometheus, and visualizes them in Grafana.
- **Centralized logging:** Collects Docker container logs using Grafana Alloy, forwards them to Loki, and makes them available for exploration in Grafana.

Grafana Alloy acts as the collection and forwarding agent for both Docker logs and Nomad telemetry.

## 2. Components

| Component | Responsibility |
|---|---|
| Nomad | Schedules and manages service workloads and exposes workload and cluster telemetry |
| Docker | Runs container workloads through the Nomad Docker task driver |
| Nginx | Sample web service and source of HTTP access logs |
| Node Exporter | Exposes host-level metrics |
| Prometheus | Scrapes, receives, and stores metrics as time series |
| Grafana Alloy | Discovers Docker containers, collects logs, scrapes Nomad telemetry, and forwards observability data |
| Loki | Receives and serves log streams |
| Grafana | Displays metrics dashboards and provides log exploration |

## 3. Overall Architecture

### 3.1 Metrics Pipeline

The metrics pipeline has two collection paths.

**Host metrics**

```text
Node Exporter ──────────────┐
                            ├──> Prometheus ──> Grafana
Nomad Telemetry ──> Alloy ──┘
```

**Nomad workload metrics**

1. Nomad exposes telemetry through its Prometheus-compatible metrics endpoint.
2. Grafana Alloy scrapes the Nomad API endpoint at `127.0.0.1:4646/v1/metrics?format=prometheus`.
3. Alloy forwards the collected metrics to Prometheus through its remote-write receiver.
4. Prometheus stores the metrics.
5. Grafana queries Prometheus to display Nomad job and allocation statistics.

The Nomad metrics integration provides visibility into information such as:

- Running, pending, and dead Nomad jobs.
- Running, pending, blocked, and terminal allocations.
- Job-level allocation summaries.
- CPU and memory allocation statistics.
- Nomad client and node statistics.

**Host metrics collection**

1. Node Exporter exposes host metrics on port `9100`.
2. Prometheus scrapes Node Exporter at the configured interval.
3. Prometheus stores the resulting time series.
4. Grafana queries Prometheus and renders dashboards.

The lab used a 15-second scrape interval for the Prometheus scrape jobs.

**Flow:** `Node Exporter → Prometheus → Grafana`

**Nomad telemetry flow:** `Nomad Telemetry → Grafana Alloy → Prometheus → Grafana`

### 3.2 Logging Pipeline

1. Nginx and the monitoring services run as Docker containers managed by Nomad.
2. Grafana Alloy discovers Docker containers through `/var/run/docker.sock`.
3. Alloy collects container logs and attaches labels, including the container name and `job="docker"`.
4. Alloy sends log entries to Loki's push API.
5. Grafana queries Loki through Explore.

**Flow:** `Docker Containers → Grafana Alloy → Loki → Grafana`

The Loki push endpoint used in the lab was:

`http://172.18.49.163:3100/loki/api/v1/push`

## 4. Nomad Telemetry Configuration

Nomad telemetry was enabled in the Nomad agent configuration:

```hcl
telemetry {
  prometheus_metrics          = true
  publish_allocation_metrics  = true
  publish_node_metrics        = true
}
```

These settings enable Prometheus-format telemetry and publish allocation and node metrics.

Grafana Alloy uses the following Nomad metrics endpoint:

`http://127.0.0.1:4646/v1/metrics?format=prometheus`

The Alloy job uses host networking, allowing it to access the Nomad agent through the local loopback address.

Alloy forwards these metrics to Prometheus using:

`http://172.18.49.163:9090/api/v1/write`

Prometheus must have its remote-write receiver enabled:

```text
--web.enable-remote-write-receiver
```

This is important because Nomad telemetry reaches Prometheus through Alloy's remote-write pipeline rather than through a separate Nomad scrape job in `prometheus/prometheus.yml`.

## 5. Endpoints Used in the Lab

The WSL host IP observed during implementation was `172.18.49.163`. WSL addresses can change after restart; update configuration files if the address changes.

| Service | Endpoint |
|---|---|
| Nomad UI | `http://127.0.0.1:4646` |
| Nomad telemetry | `http://127.0.0.1:4646/v1/metrics?format=prometheus` |
| Nginx | `http://172.18.49.163:8080` |
| Node Exporter | `http://172.18.49.163:9100/metrics` |
| Prometheus | `http://172.18.49.163:9090` |
| Prometheus targets | `http://172.18.49.163:9090/targets` |
| Prometheus remote-write receiver | `http://172.18.49.163:9090/api/v1/write` |
| Loki readiness | `http://172.18.49.163:3100/ready` |
| Grafana | `http://172.18.49.163:3000` |
| Grafana Alloy UI | `http://172.18.49.163:12345` |

## 6. Design Notes and Limitations

- Nomad ran in development mode. This is for learning and testing, not production; its state is ephemeral.
- Alloy used host networking because the local Nomad client did not have the required CNI bridge plugin available.
- Alloy mounts the Docker socket. Access to it can provide extensive control over the Docker host and must be treated as highly privileged.
- Nomad metrics are collected by Alloy and forwarded to Prometheus using remote write. Node Exporter metrics are scraped directly by Prometheus.
- Prometheus remote-write receiver support must remain enabled for the Nomad metrics integration to work.
- Node Exporter reported duplicate filesystem metric errors for some WSL mount information. This was not resolved as part of the integration.
- This is a local lab demonstration, not a hardened or highly available production architecture.