# Configuration Guide

## 1. Overview

This document explains the purpose of the configuration files used by the Nomad observability stack. The actual files in the repository are the source of truth when making changes.

The configuration covers:

- Nomad job specifications and agent telemetry.
- Prometheus scraping and remote-write reception.
- Grafana Alloy Docker log collection and Nomad metrics scraping.
- Loki storage and log ingestion.
- Grafana data source provisioning.

## 2. Configuration File Map

| File | Purpose |
|---|---|
| `nomad-dev.hcl` | Nomad development agent, Docker volume support, network interface, and telemetry settings |
| `nomad/nginx.nomad` | Nginx Nomad job |
| `nomad/node-exporter.nomad` | Node Exporter Nomad job |
| `nomad/prometheus.nomad` | Prometheus Nomad job and remote-write receiver configuration |
| `nomad/loki.nomad` | Loki Nomad job |
| `nomad/grafana.nomad` | Grafana Nomad job |
| `nomad/alloy.nomad` | Grafana Alloy Nomad job, networking, and configuration mounts |
| `prometheus/prometheus.yml` | Prometheus scrape targets and intervals |
| `loki/loki-config.yml` | Loki server, schema, and filesystem storage settings |
| `grafana/config.alloy` | Docker discovery, log forwarding, Nomad metrics scraping, and Prometheus remote write |
| `grafana/provisioning/datasources/datasources.yml` | Grafana data source provisioning |

## 3. Nomad Agent Configuration

The `nomad-dev.hcl` file configures the local Nomad development agent.

The Docker plugin configuration enables host volume mounts:

```hcl
plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}
```

The network interface is configured for the WSL environment:

```hcl
client {
  network_interface = "eth0"
}
```

### 3.1 Enable Nomad Telemetry

The telemetry block enables Prometheus-compatible metrics and publishes allocation and node statistics:

```hcl
telemetry {
  prometheus_metrics          = true
  publish_allocation_metrics  = true
  publish_node_metrics        = true
}
```

These settings allow Nomad to expose metrics that can be collected by Grafana Alloy.

The metrics endpoint used in this lab is:

`http://127.0.0.1:4646/v1/metrics?format=prometheus`

The endpoint returns metrics in Prometheus exposition format.

## 4. Prometheus Configuration

The `prometheus/prometheus.yml` file defines the global scrape interval and the targets Prometheus collects metrics from directly.

The lab uses a 15-second scrape interval and two scrape jobs:

- `prometheus`, targeting `172.18.49.163:9090`
- `node-exporter`, targeting `172.18.49.163:9100`

Nomad telemetry is not configured as a direct scrape target in this file. Instead, Alloy collects Nomad metrics and forwards them to Prometheus through remote write.

### 4.1 Enable the Remote-Write Receiver

The Prometheus Nomad job includes the following argument:

```text
--web.enable-remote-write-receiver
```

This enables Prometheus to receive metrics sent by Alloy through:

`http://172.18.49.163:9090/api/v1/write`

Without this receiver, Alloy cannot successfully forward Nomad metrics to Prometheus.

If the WSL host IP changes, update the applicable endpoints. Confirm direct scrape targets in the Prometheus UI under **Status → Targets**.

## 5. Loki Configuration

The lab used Loki image version `3.4.2` and local filesystem storage.

The configuration included:

- An HTTP listener on port `3100`.
- `auth_enabled: false` for the local lab.
- TSDB schema version `v13`.
- Filesystem-backed chunks and rules directories under `/loki`.
- An in-memory ring suitable for a single-instance lab.

An earlier configuration enabled retention without configuring `compactor.delete-request-store`, which caused Loki startup to fail.

The working lab configuration removed `retention_enabled: true`. Do not enable retention without configuring the required deletion-request storage and retention settings for the Loki version in use.

## 6. Grafana Data Sources

The provisioning file configures two data sources:

| Data source | URL | Purpose |
|---|---|---|
| Prometheus | `http://172.18.49.163:9090` | Host and Nomad metrics |
| Loki | `http://172.18.49.163:3100` | Centralized container logs |

Prometheus is configured as the default data source.

The `access: proxy` setting makes Grafana's backend communicate with the data sources. Ensure the URLs are reachable from Grafana's container network context, not merely from the host browser.

## 7. Grafana Alloy Configuration

The `grafana/config.alloy` file defines two observability pipelines.

### 7.1 Docker Log Collection

The Docker logging pipeline uses the following Alloy components:

1. `discovery.docker` discovers Docker containers through `unix:///var/run/docker.sock`.
2. `discovery.relabel` maps the Docker container name into a `container` label.
3. `loki.source.docker` reads logs from discovered containers and adds `job="docker"`.
4. `loki.write` forwards log entries to Loki's push API.

**Flow:** `Docker Containers → Alloy → Loki`

### 7.2 Nomad Metrics Collection

The Nomad metrics pipeline uses two main Alloy components:

1. `prometheus.scrape` collects Prometheus-format telemetry from the Nomad agent endpoint at `127.0.0.1:4646`.
2. `prometheus.remote_write` forwards the collected metrics to Prometheus.

The scrape component uses:

- Metrics path: `/v1/metrics`
- Query parameter: `format=prometheus`
- Target: `127.0.0.1:4646`

The remote-write endpoint is:

`http://172.18.49.163:9090/api/v1/write`

**Flow:** `Nomad Telemetry → Alloy → Prometheus`

### 7.3 Alloy Networking and Deployment

The Alloy Nomad job uses host networking because the local Nomad client lacked the required CNI bridge plugin.

The job mounts:

- `/var/run/docker.sock` for Docker discovery and log collection.
- The host's `grafana/config.alloy` file into the container at `/etc/alloy/config.alloy`.

The Alloy UI is available at:

`http://172.18.49.163:12345`

> **Security warning:** Mounting `/var/run/docker.sock` into a container is highly privileged. Treat Alloy as trusted, restrict who can modify its configuration, and do not expose the Docker socket or Alloy UI to untrusted networks.

## 8. Nomad Job Specifications

Review each file in `nomad/` for:

- Docker image and tag.
- Network mode and ports.
- Bind mounts and volume configuration.
- Environment variables.
- CPU and memory resources.
- Service registration and health checks.

Validate a job before submitting it:

```bash
nomad job validate nomad/<job-file>.nomad
```

Submit the job:

```bash
nomad job run nomad/<job-file>.nomad
```

Inspect its status:

```bash
nomad job status <job-name>
```

## 9. Environment-Specific Values

The following values are specific to this lab:

- WSL host IP: `172.18.49.163`
- Nomad metrics endpoint: `127.0.0.1:4646`
- Prometheus remote-write endpoint: `172.18.49.163:9090`
- Local Grafana credentials.
- Absolute host paths used in Nomad volume mounts.

Replace these values when deploying on another machine.

Do not commit real credentials, passwords, access keys, or secrets to source control.