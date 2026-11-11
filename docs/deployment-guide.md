# Deployment Guide

## 1. Purpose

This guide describes how the Nomad observability stack was deployed in the local WSL Ubuntu environment.

The deployment includes:

- HashiCorp Nomad for workload scheduling.
- Docker for running containerized services.
- Node Exporter for host-level metrics.
- Prometheus for metrics collection and storage.
- Grafana Alloy for Docker log collection and Nomad telemetry scraping.
- Loki for centralized log storage.
- Grafana for metrics visualization and log exploration.

## 2. Prerequisites

- Windows with WSL and Ubuntu.
- Docker Engine installed and running.
- HashiCorp Nomad installed.
- Nomad Docker task driver available.
- Project repository available in the WSL environment.

Check the installed tools:

```bash
nomad version
docker version
docker ps
```

## 3. Open the Project Directory

Navigate to the repository:

```bash
cd /mnt/c/Users/Admin/Desktop/nomad-observability-stack
```

Confirm the project files are available:

```bash
ls
```

## 4. Configure and Start the Nomad Development Agent

The `nomad-dev.hcl` file contains the local Nomad client configuration.

It enables Docker volume support and selects the WSL network interface:

```hcl
client {
  network_interface = "eth0"
}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}
```

It also enables Prometheus-compatible telemetry:

```hcl
telemetry {
  prometheus_metrics          = true
  publish_allocation_metrics  = true
  publish_node_metrics        = true
}
```

Start the Nomad development agent from the repository root:

```bash
nomad agent -dev -config="$PWD/nomad-dev.hcl"
```

Keep the agent running in its terminal.

Nomad UI:

`http://127.0.0.1:4646`

> Development mode is intended for local testing. Restarting the development agent can clear its state, so jobs may need to be submitted again.

## 5. Validate and Deploy the Jobs

Run these commands from the repository root. The job names below match the jobs used in this lab.

### 5.1 Nginx

```bash
nomad job validate nomad/nginx.nomad
nomad job run nomad/nginx.nomad
nomad job status