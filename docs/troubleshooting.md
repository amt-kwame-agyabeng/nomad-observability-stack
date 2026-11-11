# Troubleshooting Guide

This guide records the main issues encountered during the local WSL-based deployment and provides diagnostic steps for resolving common problems across Nomad, Docker, Prometheus, Grafana Alloy, Loki, and Grafana.

## 1. General Nomad Diagnostics

Check all deployed jobs:

```bash
nomad job status
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

A job can have historical failed allocations while its latest deployment and current allocation are healthy. Check the latest deployment and current allocation rather than relying only on old failed allocation entries.

## 2. Docker Volume Mounts

The Docker task driver needed volume support enabled in the Nomad client configuration.

The lab's Nomad configuration included:

```hcl
plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}
```

If a task cannot mount a host file or directory:

1. Check that Docker volume support is enabled.
2. Confirm that the host path exists.
3. Check that the path is accessible to Docker.
4. Inspect the allocation logs for mount errors.

## 3. Alloy Placement and CNI Bridge Issue

The Alloy job initially used bridge networking and could not be placed because the local Nomad client did not have the required CNI bridge plugin.

The job was changed to host networking for this local lab.

For production or multi-node use, install and configure the appropriate CNI plugins and design networking deliberately rather than assuming host networking is the preferred general solution.

## 4. Alloy Configuration Parse Errors

An early Alloy configuration had a missing trailing comma in a River configuration map.

Alloy reported a parse error similar to:

```text
missing ',' in field list
```

The map entry was corrected by adding the required comma.

When Alloy fails to start:

1. Inspect the Alloy allocation logs.
2. Check the configuration file for syntax errors.
3. Validate the configuration before redeployment.

Validate the configuration with:

```bash
docker run --rm \
  -v "$PWD/grafana/config.alloy:/etc/alloy/config.alloy:ro" \
  grafana/alloy:latest \
  validate /etc/alloy/config.alloy
```

## 5. Docker Socket Access

Alloy needs access to `/var/run/docker.sock` to discover containers and read their logs.

Check that the socket exists:

```bash
ls -l /var/run/docker.sock
```

The lab task ran as root, which allowed it to access the socket.

Docker socket access is highly privileged and should be restricted to trusted workloads.

## 6. Nomad Telemetry Is Not Available

If Nomad metrics are missing from Prometheus, first verify that the Nomad telemetry configuration is enabled.

The `nomad-dev.hcl` file should contain:

```hcl
telemetry {
  prometheus_metrics          = true
  publish_allocation_metrics  = true
  publish_node_metrics        = true
}
```

Check the Nomad metrics endpoint:

```bash
curl "http://127.0.0.1:4646/v1/metrics?format=prometheus"
```

If metrics are returned, search the output for Nomad-related metric names.

If the endpoint is unavailable:

1. Confirm the Nomad development agent is running.
2. Check that it was started with the intended configuration file.
3. Verify that the telemetry settings are present.
4. Check Nomad agent logs for configuration errors.

## 7. Alloy Cannot Scrape Nomad Metrics

Alloy uses the following target:

```text
127.0.0.1:4646
```

The Alloy Nomad job uses host networking, allowing it to reach the Nomad agent through the host's loopback interface.

If scraping fails:

1. Confirm that Nomad is listening on port `4646`.
2. Confirm that the telemetry endpoint returns metrics.
3. Verify that the Alloy job uses host networking.
4. Check the `prometheus.scrape "nomad"` component in `grafana/config.alloy`.
5. Inspect Alloy's UI and allocation logs.

The Alloy scrape configuration should use:

```hcl
metrics_path = "/v1/metrics"

params = {
  "format" = ["prometheus"],
}
```

A mismatch between the network mode and scrape target can prevent Alloy from reaching the Nomad API.

## 8. Prometheus Remote-Write Errors

Alloy forwards Nomad metrics to Prometheus through the remote-write receiver.

The Prometheus job must include:

```text
--web.enable-remote-write-receiver
```

The Alloy configuration should forward metrics to:

```text
http://172.18.49.163:9090/api/v1/write
```

If remote-write requests fail:

1. Confirm that Prometheus is running.
2. Verify that the remote-write receiver flag is enabled.
3. Check the remote-write URL in `grafana/config.alloy`.
4. Confirm that the WSL host IP has not changed.
5. Inspect Alloy and Prometheus allocation logs.

Without the remote-write receiver, Prometheus will not accept Alloy's incoming metrics through this endpoint.

## 9. Nomad Metrics Missing in Prometheus or Grafana

If Nomad metrics are available from the Nomad API but not in Prometheus:

1. Check that the Alloy job is running.
2. Confirm that Alloy's Nomad scrape component is healthy.
3. Check the remote-write receiver configuration.
4. Inspect Alloy logs for connection or forwarding errors.
5. Run a Nomad metric query in Prometheus:

```promql
{__name__=~".*nomad.*"}
```

To inspect job statistics:

```promql
{__name__=~".*nomad.*job.*"}
```

To inspect allocation statistics:

```promql
{__name__=~".*nomad.*allocation.*"}
```

If Prometheus returns the metrics but Grafana does not:

1. Confirm that Grafana uses the correct Prometheus data source.
2. Check that the dashboard queries use available metric names.
3. Set an appropriate dashboard time range.
4. Refresh the dashboard.

Metric names and available series can vary depending on the Nomad version and telemetry configuration.

## 10. Loki Startup and Retention Configuration

An earlier Loki configuration enabled retention without configuring the required `compactor.delete-request-store`.

Loki failed to start with a configuration error.

The working lab setup removed:

```yaml
retention_enabled: true
```

If retention is required, configure the deletion-request store and compactor settings supported by the deployed Loki version.

Check readiness:

```bash
curl http://172.18.49.163:3100/ready
```

Inspect Loki allocation logs if it does not return `ready`.

## 11. Prometheus Targets Are DOWN

Open:

`http://172.18.49.163:9090/targets`

Then:

1. Check the target's reported error.
2. Confirm the target service is running in Nomad.
3. Test the endpoint from the relevant network context.
4. Check the scrape target IP and port in `prometheus/prometheus.yml`.
5. Update the IP if the WSL address changed.

Remember that Nomad metrics are forwarded through Alloy remote write and are not represented as a direct Nomad scrape target in the Prometheus targets page.

## 12. Grafana Data Source Connection Problems

Check that the Prometheus and Loki URLs in:

`grafana/provisioning/datasources/datasources.yml`

are reachable from Grafana's container network.

A URL that works in the host browser may not work from another container.

Verify Grafana health:

```bash
curl http://172.18.49.163:3000/api/health
```

## 13. Node Exporter Duplicate Filesystem Metrics

During the WSL lab, Node Exporter logged duplicate filesystem metric errors for some mount information, including entries associated with `/run/user` and `tmpfs`.

This was not resolved as part of the completed logging and Nomad telemetry integration.

Investigate separately if filesystem metrics are incomplete or unreliable. Do not describe this issue as fixed.

## 14. Nginx Logs Do Not Appear in Grafana

Generate requests:

```bash
for i in {1..10}; do
  curl -s -o /dev/null http://172.18.49.163:8080
done
```

Then:

1. Confirm Alloy is running:

```bash
nomad job status alloy
```

2. Check Alloy allocation logs.
3. Confirm Loki is ready.
4. In Grafana Explore, select Loki and query:

```logql
{job="docker"}
```

To isolate Nginx GET requests made by curl:

```logql
{job="docker", container=~".*nginx.*"} |= "\\\"GET " |= "curl/"
```

The `container` label depends on Alloy relabeling. If no results appear, inspect the actual labels in Loki and adjust the selector.

## 15. WSL Host IP Changes

The lab used `172.18.49.163`, which may change after a WSL restart.

If services become unreachable:

1. Identify the current WSL IP.
2. Update the affected configuration files.
3. Check Prometheus, Loki, Grafana, and Alloy endpoints.
4. Redeploy or restart affected jobs where necessary.

The Nomad telemetry target `127.0.0.1:4646` is intentionally local to Alloy because its job uses host networking.