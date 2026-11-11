# Command Reference

A consolidated reference for commands used to operate, inspect, and verify the Nomad observability lab.

> The host IP `172.18.49.163` and project paths are specific to the original WSL environment. Replace them if your environment differs.

## 1. Navigate to the Repository

```bash
cd /mnt/c/Users/Admin/Desktop/nomad-observability-stack
```

## 2. Check Installed Tools

```bash
nomad version
docker version
docker ps
docker ps -a
```

## 3. Start Nomad

```bash
nomad agent -dev -config="$PWD/nomad-dev.hcl"
```

Keep the agent running in its terminal.

## 4. Validate and Run Jobs

```bash
nomad job validate nomad/nginx.nomad
nomad job run nomad/nginx.nomad
nomad job status nginx

nomad job validate nomad/node-exporter.nomad
nomad job run nomad/node-exporter.nomad
nomad job status node-exporter

nomad job validate nomad/prometheus.nomad
nomad job run nomad/prometheus.nomad
nomad job status prometheus

nomad job validate nomad/loki.nomad
nomad job run nomad/loki.nomad
nomad job status loki

nomad job validate nomad/grafana.nomad
nomad job run nomad/grafana.nomad
nomad job status grafana

nomad job validate nomad/alloy.nomad
nomad job run nomad/alloy.nomad
nomad job status alloy
```

## 5. Nomad Inspection Commands

List all jobs:

```bash
nomad job status
```

Inspect nodes:

```bash
nomad node status
```

Inspect a specific job:

```bash
nomad job status <job-name>
```

Inspect an allocation:

```bash
nomad alloc status <allocation-id>
```

View allocation logs:

```bash
nomad alloc logs <allocation-id>
```

View logs for a specific task:

```bash
nomad alloc logs -task <task-name> <allocation-id>
```

Inspect Nomad server members:

```bash
nomad server members
```

Stop a job when required:

```bash
nomad job stop <job-name>
```

## 6. Service Health Checks

```bash
curl http://127.0.0.1:4646/v1/status/leader
curl http://127.0.0.1:4646/v1/metrics?format=prometheus

curl http://172.18.49.163:8080
curl http://172.18.49.163:9100/metrics
curl http://172.18.49.163:9090/-/healthy
curl http://172.18.49.163:3100/ready
curl http://172.18.49.163:3000/api/health
```

## 7. Generate Nginx Traffic

Generate five requests:

```bash
for i in {1..5}; do
  curl -s -o /dev/null http://172.18.49.163:8080
done
```

Generate ten requests:

```bash
for i in {1..10}; do
  curl -s -o /dev/null http://172.18.49.163:8080
done
```

Generate fifty requests:

```bash
for i in {1..50}; do
  curl -s -o /dev/null http://172.18.49.163:8080
done
```

## 8. Prometheus Queries

Prometheus UI:

`http://172.18.49.163:9090`

Targets page:

`http://172.18.49.163:9090/targets`

Check target availability:

```promql
up
```

Check Nomad-related metrics:

```promql
{__name__=~".*nomad.*"}
```

Check Nomad job statistics:

```promql
{__name__=~".*nomad.*job.*"}
```

Check Nomad allocation statistics:

```promql
{__name__=~".*nomad.*allocation.*"}
```

Check running Nomad jobs:

```promql
nomad_nomad_job_status_running
```

Check running allocations:

```promql
nomad_client_allocations_running
```

Check allocation CPU usage:

```promql
nomad_client_allocs_cpu_total_percent
```

Check allocation memory usage in MiB:

```promql
nomad_client_allocs_memory_usage / 1024 / 1024
```

The available metrics depend on the Nomad version and telemetry configuration.

## 9. Loki and LogQL Queries

Run these queries in Grafana Explore with Loki selected as the data source.

All Docker container logs:

```logql
{job="docker"}
```

Nginx container logs:

```logql
{job="docker", container=~".*nginx.*"}
```

Nginx GET requests:

```logql
{job="docker", container=~".*nginx.*"} |= "\\\"GET "
```

Nginx GET requests made with curl:

```logql
{job="docker", container=~".*nginx.*"} |= "\\\"GET " |= "curl/"
```

## 10. Grafana and Alloy

Grafana:

`http://172.18.49.163:3000`

Grafana Alloy UI:

`http://172.18.49.163:12345`

Prometheus data source:

`http://172.18.49.163:9090`

Loki data source:

`http://172.18.49.163:3100`

Check Grafana health:

```bash
curl http://172.18.49.163:3000/api/health
```

## 11. Docker Socket Check

```bash
ls -l /var/run/docker.sock
```

Alloy requires access to this socket for Docker container discovery and log collection.

## 12. Screenshot Directory Commands

Create the screenshot directory if it does not exist:

```bash
mkdir -p screenshots
```

List screenshot files:

```bash
ls -lh screenshots/
```

Count PNG screenshots:

```bash
find screenshots/ -maxdepth 1 -type f -name "*.png" | wc -l
```

## 13. Git Documentation Checks

Check for whitespace errors:

```bash
git diff --check
```

Review modified files:

```bash
git status
```

Review the change summary:

```bash
git diff --stat
```