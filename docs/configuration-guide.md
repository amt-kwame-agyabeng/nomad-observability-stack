# Configuration Guide

This document explains the purpose of the configuration files used by the observability stack. The actual files in the repository are the source of truth when making changes.

## Configuration file map

| File | Purpose |
|---|---|
| `nomad/nginx.nomad` | Nginx Nomad job |
| `nomad/node-exporter.nomad` | Node Exporter Nomad job |
| `nomad/prometheus.nomad` | Prometheus Nomad job |
| `nomad/loki.nomad` | Loki Nomad job |
| `nomad/grafana.nomad` | Grafana Nomad job |
| `nomad/alloy.nomad` | Grafana Alloy Nomad job |
| `prometheus/prometheus.yml` | Prometheus scrape targets and intervals |
| `loki/loki-config.yml` | Loki server, schema, and filesystem storage settings |
| `grafana/config.alloy` | Docker discovery, relabeling, and Loki forwarding |
| `grafana/provisioning/datasources/datasources.yml` | Grafana data source provisioning |

## Prometheus

The lab's `prometheus/prometheus.yml` configured a global scrape interval of 15 seconds and two scrape jobs:

- `prometheus`, targeting `172.18.49.163:9090`
- `node-exporter`, targeting `172.18.49.163:9100`

If the WSL host IP changes, update these targets. Confirm the effective configuration in the Prometheus UI under **Status → Targets**.

## Loki

The lab used Loki image version `3.4.2` and local filesystem storage. The configuration included an HTTP listener on port `3100`, `auth_enabled: false` for the local lab, TSDB schema version `v13`, filesystem-backed chunks and rules directories under `/loki`, and an in-memory ring suitable for a single-instance lab.

An earlier configuration enabled retention without configuring `compactor.delete-request-store`, which caused Loki startup to fail. The working lab configuration removed `retention_enabled: true`. Do not enable retention without configuring the required deletion-request storage and retention settings for the Loki version in use.

## Grafana data sources

The provisioning file configured Prometheus at `http://172.18.49.163:9090` as the default data source and Loki at `http://172.18.49.163:3100`.

The `access: proxy` setting makes Grafana's backend communicate with the data sources. Ensure the URLs are reachable from Grafana's container network context, not merely from the host browser.

## Grafana Alloy

The lab's `grafana/config.alloy` performs four main operations:

1. `discovery.docker` discovers Docker containers through `unix:///var/run/docker.sock`.
2. `discovery.relabel` maps the Docker container name into a `container` label.
3. `loki.source.docker` reads logs from discovered containers and adds `job="docker"`.
4. `loki.write` forwards log entries to Loki's push API.

The Alloy Nomad job used host networking because the local Nomad client lacked the required CNI bridge plugin. It mounted the Docker socket and Alloy configuration file into the container.

> **Security warning:** Mounting `/var/run/docker.sock` into a container is highly privileged. Treat Alloy as trusted, restrict who can modify its configuration, and do not expose the Docker socket or Alloy UI to untrusted networks.

## Nomad job specifications

Review each file in `nomad/` for the Docker image and tag, network mode and ports, bind mounts, environment variables, CPU and memory resources, service registration, and health checks.

Validate before submitting:

```bash
nomad job validate nomad/<job-file>.nomad
```

Submit:

```bash
nomad job run nomad/<job-file>.nomad
```

## Environment-specific values

The IP `172.18.49.163`, absolute host paths under `/home/kwamzzy`, and local Grafana credentials are specific to this lab. Replace them for another machine. Do not commit real credentials or secrets to source control.
