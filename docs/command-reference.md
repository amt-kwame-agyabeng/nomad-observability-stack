# Command Reference

A consolidated reference for commands used to operate and verify the Nomad observability lab.

> The host IP `172.18.49.163` and paths under `/home/kwamzzy` are specific to the original WSL environment. Replace them if your environment differs.

## Navigate to the repository

```bash
cd ~/projects/nomad-observability-stack
```

## Check installed tools

```bash
nomad version
docker version
docker ps
docker ps -a
```

## Start Nomad

```bash
nomad agent -dev -config=/home/kwamzzy/nomad-dev.hcl
```

Keep the agent running in its terminal.

## Validate and run jobs

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

## Nomad inspection commands

```bash
nomad job status
nomad node status
nomad job status <job-name>
nomad alloc status <allocation-id>
nomad alloc logs <allocation-id>
nomad alloc logs -task <task-name> <allocation-id>
nomad server members
```

Stop a job when required:

```bash
nomad job stop <job-name>
```

## Service health checks

```bash
curl http://172.18.49.163:8080
curl http://172.18.49.163:9100/metrics
curl http://172.18.49.163:9090/-/healthy
curl http://172.18.49.163:3100/ready
curl http://172.18.49.163:3000/api/health
```

## Generate Nginx traffic

```bash
for i in {1..5}; do
  curl -s -o /dev/null http://172.18.49.163:8080
done

for i in {1..10}; do
  curl -s -o /dev/null http://172.18.49.163:8080
done

for i in {1..50}; do
  curl -s -o /dev/null http://172.18.49.163:8080
done
```

## Prometheus query

In the Prometheus expression browser, run:

```promql
up
```

Targets page: `http://172.18.49.163:9090/targets`

## Loki / LogQL queries

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

Run these queries in Grafana Explore with Loki selected as the data source.

## Docker socket check

```bash
ls -l /var/run/docker.sock
```

## Screenshot directory commands

```bash
mkdir -p ~/projects/nomad-observability-stack/screenshots
cp /mnt/c/Users/Admin/Desktop/*.png ~/projects/nomad-observability-stack/screenshots/
ls -lh ~/projects/nomad-observability-stack/screenshots/
find ~/projects/nomad-observability-stack/screenshots/ -maxdepth 1 -type f -name "*.png" | wc -l
```
