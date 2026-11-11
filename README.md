# Nomad-Based Monitoring and Centralized Logging Stack

## 1. Project Overview

This project demonstrates how to deploy an integrated monitoring and centralized logging environment using **HashiCorp Nomad**, **Docker**, **Prometheus**, **Grafana Alloy**, **Loki**, and **Grafana**.

The stack monitors host-level resource usage, collects container logs, captures Nomad job and allocation statistics, stores metrics and logs, and provides a central interface for visualization and troubleshooting.

The implementation uses:

- **Nomad** to schedule and manage services and workloads.
- **Docker** as the container runtime.
- **Nginx** as a sample application that generates access logs.
- **Node Exporter** to expose host-level metrics.
- **Prometheus** to scrape and store metrics.
- **Grafana Alloy** to discover Docker containers, collect their logs, scrape Nomad telemetry, and forward collected data.
- **Loki** to receive and store logs.
- **Grafana** to visualize metrics and query logs.

### Project objectives

1. Deploy monitoring and logging components as Nomad jobs.
2. Collect host metrics such as CPU, memory, filesystem, and network statistics.
3. Scrape host and application metrics with Prometheus.
4. Collect Docker container logs using Grafana Alloy.
5. Forward container logs to Loki.
6. Collect Nomad job, allocation, and node telemetry through Grafana Alloy.
7. Forward Nomad metrics to Prometheus for monitoring.
8. Use Grafana as the central interface for dashboards and log exploration.
9. Document a repeatable deployment and verification process.

## 2. Architecture

The solution consists of two main observability pipelines: a metrics pipeline and a centralized logging pipeline.

### 2.1 Overall Monitoring and Logging Architecture

**Metrics Pipeline**

```text
Node Exporter ───────────────────┐
                                 ├──> Prometheus ──> Grafana
Nomad Telemetry ──> Grafana Alloy┘
```

**Logging Pipeline**

```text
Docker Containers ──> Grafana Alloy ──> Loki ──> Grafana
```

### 2.2 Metrics Pipeline

The metrics pipeline collects information from both the host environment and the Nomad cluster.

Node Exporter exposes host-level metrics, while Nomad provides telemetry relating to jobs, allocations, clients, and nodes.

Grafana Alloy scrapes the Nomad Prometheus metrics endpoint and forwards the collected metrics to Prometheus through its remote-write receiver.

Prometheus also scrapes Node Exporter directly and stores the collected metrics. Grafana uses Prometheus as a data source to visualize infrastructure and Nomad statistics.

**Flows:**

```text
Node Exporter → Prometheus → Grafana
```

```text
Nomad Telemetry → Grafana Alloy → Prometheus → Grafana
```

### 2.3 Logging Pipeline

Grafana Alloy discovers Docker containers through the Docker socket, collects their logs, and forwards them to Loki.

Grafana queries Loki to display the collected log streams and support troubleshooting.

**Flow:**

```text
Docker Containers → Grafana Alloy → Loki → Grafana
```

### 2.4 Component Responsibilities

| Component | Responsibility |
|---|---|
| Nomad | Schedules and manages service jobs and allocations |
| Docker | Runs container workloads |
| Nginx | Sample web service and source of access logs |
| Node Exporter | Exposes host-level metrics |
| Prometheus | Scrapes and stores metrics |
| Grafana Alloy | Discovers containers, collects logs, scrapes Nomad telemetry, and forwards data |
| Loki | Stores and serves log data |
| Grafana | Provides dashboards and log exploration |

## 3. Repository Structure

The project is organized so that Nomad job specifications are separate from service configuration files, supporting documentation, and screenshots.

```text
nomad-observability-stack/
├── README.md
├── nomad-dev.hcl
├── .gitignore
│
├── docs/
│   ├── architecture.md
│   ├── deployment-guide.md
│   ├── configuration-guide.md
│   ├── troubleshooting.md
│   └── command-reference.md
│
├── grafana/
│   ├── provisioning/
│   │   └── datasources/
│   │       └── datasources.yml
│   └── config.alloy
│
├── loki/
│   └── loki-config.yml
│
├── nomad/
│   ├── nginx.nomad
│   ├── node-exporter.nomad
│   ├── prometheus.nomad
│   ├── loki.nomad
│   ├── grafana.nomad
│   └── alloy.nomad
│
├── prometheus/
│   └── prometheus.yml
│
└── screenshots/
```

## 4. Deployment Environment and Prerequisites

The lab was implemented in Ubuntu running under Windows Subsystem for Linux (WSL), using Nomad in development mode and Docker Engine.

### Prerequisites

- Windows with WSL and an Ubuntu distribution.
- Docker Engine installed and running inside the environment.
- HashiCorp Nomad installed.
- The Nomad Docker task driver available.
- The project repository cloned or copied into the WSL filesystem.

Check the installed versions:

```bash
nomad version
docker version
```

### 4.1 Nomad development configuration

The Nomad development agent was started from the project root using:

```bash
nomad agent -dev -config="$PWD/nomad-dev.hcl"
```

The lab configuration enables Docker volume support, selects the WSL network interface, and enables Nomad Prometheus telemetry.

The telemetry configuration includes:

```hcl
telemetry {
  prometheus_metrics         = true
  publish_allocation_metrics = true
  publish_node_metrics       = true
}
```

These settings expose Nomad metrics, including job, allocation, and node statistics.

Keep the Nomad agent running while using the lab.

> **Important:** Nomad development mode is intended for testing and learning, not production. Its state is ephemeral. Restarting the development agent can remove the jobs and state created during the session, so the jobs may need to be submitted again.

Nomad UI:

`http://127.0.0.1:4646`

### 4.2 Network addressing

During this implementation, the WSL host IP was `172.18.49.163`. The endpoints below use that address.

WSL IP addresses can change after a restart. If they do, update the IP address in the relevant Prometheus, Grafana, Loki, and Alloy configuration files and in any host-specific Nomad settings.

| Service | Endpoint |
|---|---|
| Nginx | `http://172.18.49.163:8080` |
| Node Exporter | `http://172.18.49.163:9100/metrics` |
| Prometheus | `http://172.18.49.163:9090` |
| Loki readiness | `http://172.18.49.163:3100/ready` |
| Grafana | `http://172.18.49.163:3000` |
| Grafana Alloy UI | `http://172.18.49.163:12345` |

For another machine or environment, replace the example IP with the correct reachable address.

## 5. Configuration Overview

The main configuration files are:

| File | Purpose |
|---|---|
| `nomad-dev.hcl` | Nomad development agent and telemetry configuration |
| `nomad/nginx.nomad` | Nginx Nomad job |
| `nomad/node-exporter.nomad` | Node Exporter Nomad job |
| `nomad/prometheus.nomad` | Prometheus Nomad job |
| `nomad/loki.nomad` | Loki Nomad job |
| `nomad/grafana.nomad` | Grafana Nomad job |
| `nomad/alloy.nomad` | Grafana Alloy Nomad job |
| `prometheus/prometheus.yml` | Prometheus scrape configuration |
| `loki/loki-config.yml` | Loki server and storage configuration |
| `grafana/config.alloy` | Alloy container discovery, log forwarding, and Nomad metrics collection |
| `grafana/provisioning/datasources/datasources.yml` | Grafana Prometheus and Loki data sources |

### 5.1 Prometheus scrape configuration

Prometheus is configured to scrape itself and Node Exporter.

The configured scrape interval is 15 seconds.

The targets used in this lab are:

- Prometheus: `172.18.49.163:9090`
- Node Exporter: `172.18.49.163:9100`

Nomad telemetry is collected separately by Grafana Alloy and forwarded to Prometheus using remote write.

The Prometheus job also enables its remote-write receiver:

```text
--web.enable-remote-write-receiver
```

This allows Alloy to forward Nomad metrics to:

`http://172.18.49.163:9090/api/v1/write`

If the host IP changes, update `prometheus/prometheus.yml`, the relevant Nomad job configuration, and the Alloy configuration.

### 5.2 Grafana data sources

Grafana is provisioned with two data sources:

- **Prometheus** for infrastructure and Nomad metrics.
- **Loki** for container logs.

This allows monitoring and log investigation from the same Grafana interface.

### 5.3 Grafana Alloy configuration

Grafana Alloy performs two main collection tasks in this project.

**Docker log collection**

Alloy uses Docker container discovery through the Docker socket:

`/var/run/docker.sock`

It discovers containers, relabels the container name into a `container` label, and forwards logs to Loki at:

`http://172.18.49.163:3100/loki/api/v1/push`

**Nomad telemetry collection**

Alloy also scrapes the Nomad Prometheus metrics endpoint:

`http://127.0.0.1:4646/v1/metrics?format=prometheus`

The Alloy task uses host networking in this lab, allowing it to access the Nomad agent through `127.0.0.1:4646`.

Collected Nomad metrics are forwarded to Prometheus through:

`http://172.18.49.163:9090/api/v1/write`

This enables monitoring of Nomad job status, allocation status, and resource usage.

> **Security consideration:** The Docker socket mount gives the Alloy container broad control over the Docker host. This configuration should only be used in a trusted local lab unless stronger isolation and access controls are designed.

## 6. Deployment Procedure

Run the commands from the root of the repository:

```bash
cd /mnt/c/Users/Admin/Desktop/nomad-observability-stack
```

Keep the Nomad agent running in a separate terminal.

### Step 1: Validate and deploy Nginx

```bash
nomad job validate nomad/nginx.nomad
nomad job run nomad/nginx.nomad
nomad job status nginx
```

Open `http://172.18.49.163:8080` and confirm that the Nginx page loads.

### Step 2: Validate and deploy Node Exporter

```bash
nomad job validate nomad/node-exporter.nomad
nomad job run nomad/node-exporter.nomad
nomad job status node-exporter
```

Open `http://172.18.49.163:9100/metrics` and confirm that metrics are returned.

### Step 3: Validate and deploy Prometheus

```bash
nomad job validate nomad/prometheus.nomad
nomad job run nomad/prometheus.nomad
nomad job status prometheus
```

Open `http://172.18.49.163:9090/targets`.

Confirm that the Prometheus and Node Exporter scrape targets are healthy.

### Step 4: Validate and deploy Loki

```bash
nomad job validate nomad/loki.nomad
nomad job run nomad/loki.nomad
nomad job status loki
```

Check readiness:

```bash
curl http://172.18.49.163:3100/ready
```

A successful response is:

```text
ready
```

### Step 5: Validate and deploy Grafana

```bash
nomad job validate nomad/grafana.nomad
nomad job run nomad/grafana.nomad
nomad job status grafana
```

Open:

`http://172.18.49.163:3000`

Use the administrator credentials configured for the Grafana deployment. Do not commit passwords or other secrets to source control.

### Step 6: Validate and deploy Grafana Alloy

```bash
nomad job validate nomad/alloy.nomad
nomad job run nomad/alloy.nomad
nomad job status alloy
```

Open:

`http://172.18.49.163:12345`

Confirm that the Alloy UI is accessible and the configuration has loaded.

> The deployment commands above assume the Nomad job names and file paths match this repository structure. If a job has a different name in its HCL file, use the job name defined in that file when checking its status.

## 7. Verification and Testing

### 7.1 Verify Nomad jobs

List the jobs:

```bash
nomad job status
```

Inspect an individual job:

```bash
nomad job status <job-name>
```

Inspect an allocation:

```bash
nomad alloc status <allocation-id>
```

The expected state for each active service is `running`, with its desired allocation healthy.

### 7.2 Verify Prometheus targets

Open:

`http://172.18.49.163:9090/targets`

The Prometheus and Node Exporter scrape targets should show as **UP**.

You can also open the Prometheus graph page and run:

```promql
up
```

A value of `1` indicates that the corresponding target is being scraped successfully.

### 7.3 Verify Nomad telemetry in Prometheus

Open the Prometheus expression browser:

`http://172.18.49.163:9090`

Run the following query to identify Nomad metrics:

```promql
{__name__=~".*nomad.*"}
```

To inspect Nomad job-related metrics:

```promql
{__name__=~".*nomad.*job.*"}
```

To inspect allocation-related metrics:

```promql
{__name__=~".*nomad.*allocation.*"}
```

These queries help verify that Nomad telemetry is available in Prometheus.

Examples of statistics exposed include:

- Running, pending, and dead job counts.
- Running, pending, blocked, and terminal allocation counts.
- Job summaries.
- Allocation CPU and memory statistics.
- Nomad client and node information.

Metric values change as jobs and allocations are deployed, stopped, or restarted.

### 7.4 Verify Grafana metrics

Open Grafana and select the provisioned Prometheus data source.

The Node Exporter Full dashboard used in this lab has dashboard ID `1860`. It displays system information such as:

- CPU utilization.
- Memory usage.
- Filesystem capacity and usage.
- Disk activity.
- Network traffic.
- System uptime.

A separate Nomad monitoring dashboard was also created to visualize:

- Running Nomad jobs.
- Running allocations.
- CPU usage per allocation.
- Memory usage per allocation.

The dashboard uses Prometheus metrics forwarded by Alloy.

### 7.5 Verify log collection in Grafana

Open Grafana Explore:

`http://172.18.49.163:3000/explore`

Select **Loki** as the data source and run:

```logql
{job="docker"}
```

This query displays Docker container logs carrying the `job="docker"` label.

To filter for Nginx GET requests generated by curl, use:

```logql
{job="docker", container=~".*nginx.*"} |= "\"GET " |= "curl/"
```

Generate sample requests from the WSL terminal:

```bash
for i in {1..10}; do
  curl -s -o /dev/null http://172.18.49.163:8080
done
```

Run the query again in Grafana Explore. The results should include Nginx access log entries with a `GET` request and a curl user agent.

The Nginx access logs demonstrate the full logging path:

```text
Nginx container → Docker logs → Alloy → Loki → Grafana Explore
```

## 8. Screenshots and Evidence

The `screenshots/` directory contains **25 screenshots** captured during deployment, configuration, and verification.

### 8.1 Nomad and Consul

**Nomad interface**

![Nomad interface](screenshots/nomad.png)

**Nomad client details**

![Nomad client details](screenshots/03-nomad-client-details.png)

**Consul interface**

![Consul interface](screenshots/consul.png)

**Consul members**

![Consul members](screenshots/04-consul-members.png)

### 8.2 Nginx deployment

**Nginx application**

![Nginx application](screenshots/05-application-nginx.png)

**Nginx Nomad job**

![Nginx Nomad job](screenshots/06-nginx-nomad-job.png)

**Nginx Consul health check**

![Nginx Consul health check](screenshots/07-nginx-consul-health.png)

### 8.3 Node Exporter and Prometheus

**Node Exporter job**

![Node Exporter job](screenshots/node-exporter-job.png)

**Node Exporter metrics**

![Node Exporter metrics](screenshots/node-exporter-metrics.png)

**Prometheus interface**

![Prometheus interface](screenshots/prometheus.png)

**Prometheus metrics query**

![Prometheus metrics query](screenshots/prometheus-metrics.png)

**Prometheus targets**

![Prometheus targets](screenshots/prometheus-targets.png)

### 8.4 Grafana, Loki, and Alloy

**Grafana dashboard**

![Grafana dashboard](screenshots/grafana-dashboard.png)

**Additional dashboard view**

![Additional dashboard](screenshots/dashboard.png)

**Grafana Alloy interface**

![Grafana Alloy interface](screenshots/grafana-alloy-ui.png)

**Loki readiness check**

![Loki readiness](screenshots/loki-ready.png)

**Loki log volume**

![Loki log volume](screenshots/loki-log-volume.png)

**Grafana Explore logs**

![Grafana Explore logs](screenshots/grafana-explore-logs.png)

**Filtered Nginx access logs**

![Filtered Nginx access logs](screenshots/16-nginx-access-logs.png)

### 8.5 Nomad Telemetry and Grafana Monitoring

The following screenshots provide evidence of the extended monitoring implementation, where Grafana Alloy collects Nomad telemetry and forwards the metrics to Prometheus for visualization in Grafana.

**Nomad telemetry configuration**

![Nomad telemetry configuration](screenshots/nomad-telemetry-config.png)

Shows the Nomad agent configuration with Prometheus metrics, allocation metrics, and node metrics enabled.

**Grafana Alloy Nomad metrics configuration**

![Alloy Nomad configuration](screenshots/alloy-nomad-config.png)

Shows the Alloy Prometheus scrape configuration targeting the Nomad metrics endpoint.

**Grafana Alloy deployment**

![Alloy deployment](screenshots/alloy-deployment.png)

Shows the successful deployment of Grafana Alloy as a Nomad job.

**Nomad metrics in Prometheus**

![Prometheus Nomad metrics](screenshots/prometheus-nomad-metrics.png)

Demonstrates that Nomad telemetry is successfully collected and available in Prometheus.

**Nomad job statistics in Prometheus**

![Prometheus job statistics](screenshots/prometheus-job-statistics.png)

Shows the Nomad job statistics exposed through Prometheus queries.

**Nomad Grafana monitoring dashboard**

![Nomad Grafana dashboard](screenshots/nomad-grafana-dashboard.png)

Displays the Grafana dashboard created to monitor running Nomad jobs, running allocations, CPU usage per allocation, and memory usage per allocation.

## 9. Troubleshooting

### 9.1 Nomad job is not running

Check the job and allocation:

```bash
nomad job status <job-name>
nomad alloc status <allocation-id>
```

Inspect task logs:

```bash
nomad alloc logs <allocation-id>
```

Use the allocation ID shown by Nomad for the affected job.

### 9.2 Prometheus target is DOWN

Check that:

- The target service is running.
- The target address and port are correct.
- The metrics endpoint is reachable from the Prometheus task.
- The scrape configuration is valid.
- Host firewall and network settings permit the connection.

### 9.3 Nomad metrics are missing from Prometheus

Check that:

- Prometheus telemetry is enabled in `nomad-dev.hcl`.
- The Nomad agent is running.
- Alloy is deployed and its configuration has loaded.
- Alloy can reach the Nomad metrics endpoint.
- The Prometheus remote-write receiver is enabled.
- The remote-write endpoint in Alloy points to the correct Prometheus address.

Useful Prometheus query:

```promql
{__name__=~".*nomad.*"}
```

### 9.4 Loki is not ready

Inspect the Loki allocation logs:

```bash
nomad alloc logs <allocation-id>
```

Check the Loki configuration and confirm that its configured storage paths are available and writable.

### 9.5 Alloy is not forwarding logs

Check that:

- The Alloy allocation is running.
- The Alloy configuration file is mounted at the expected path.
- The Docker socket is mounted and accessible.
- The Loki push endpoint is reachable from Alloy.
- Alloy reports no configuration or connection errors.

### 9.6 Duplicate Node Exporter filesystem metrics

During this WSL lab, Node Exporter reported duplicate filesystem metric errors for some mount information. This is an environment-specific issue that should be investigated if it affects the completeness or reliability of filesystem metrics. It does not, by itself, demonstrate a failure of the Alloy-to-Loki logging pipeline.

For additional troubleshooting commands and configuration checks, refer to [the Troubleshooting Guide](docs/troubleshooting.md).

## 10. Security and Production Considerations

This implementation is a local development lab, not a production-ready deployment.

Before adapting it for production:

- Replace default Grafana credentials and store secrets securely.
- Restrict access to Nomad, Grafana, Prometheus, Loki, and Alloy.
- Use authentication and authorization appropriate to the environment.
- Avoid exposing the Docker socket to workloads unless strictly necessary. Access to it can provide extensive control over the Docker host.
- Use persistent storage for metrics and logs, with backup and recovery procedures.
- Define log retention, storage limits, and monitoring data retention policies.
- Use TLS for network connections where appropriate.
- Apply least-privilege permissions to service accounts and host resources.
- Review container images, versions, and update procedures.
- Avoid committing credentials, tokens, or other secrets to source control.

## 11. Conclusion

This project demonstrates an integrated monitoring and centralized logging solution using Nomad and Docker.

Prometheus collects host-level metrics exposed by Node Exporter, while Grafana Alloy discovers Docker containers and forwards their logs to Loki.

The implementation was extended to include Nomad telemetry collection. Alloy scrapes the Nomad metrics endpoint and forwards job, allocation, and node statistics to Prometheus. Grafana provides dashboards for monitoring infrastructure performance and Nomad workload activity, alongside log exploration through Loki.

The completed lab provides a practical foundation that can be extended to monitor additional containerized services and support more advanced observability practices.

## 12. Supporting Documentation

This repository includes supporting documentation covering the architecture, deployment, configuration, troubleshooting, and operational commands.

- [Architecture Guide](docs/architecture.md)
- [Deployment Guide](docs/deployment-guide.md)
- [Configuration Guide](docs/configuration-guide.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Command Reference](docs/command-reference.md)