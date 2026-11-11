# Troubleshooting Guide

This guide records the main issues encountered during the local WSL-based deployment and the checks used to diagnose them.

## General Nomad diagnostics

```bash
nomad job status
nomad job status <job-name>
nomad alloc status <allocation-id>
nomad alloc logs <allocation-id>
nomad alloc logs -task <task-name> <allocation-id>
```

A job can have historical failed allocations while its latest deployment and current allocation are healthy. Check the latest deployment and current allocation rather than relying only on old failed allocation entries.

## Docker volume mounts

The Docker task driver needed volume support enabled in the Nomad client configuration. The lab's Nomad configuration included:

```hcl
plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}
```

If a task cannot mount a host file or directory, check that Docker volume support is enabled and that the host path exists and is accessible.

## Alloy placement and CNI bridge issue

The Alloy job initially used bridge networking and could not be placed because the local Nomad client did not have the required CNI bridge plugin. The job was changed to host networking for this local lab.

For production or multi-node use, install and configure the appropriate CNI plugins and design networking deliberately rather than assuming host networking is the preferred general solution.

## Alloy configuration parse error

An early Alloy configuration had a missing trailing comma in a River configuration map. Alloy reported a parse error similar to `missing ',' in field list`. The map entry was corrected by adding the comma. When Alloy fails to start, inspect allocation logs and validate the configuration syntax.

## Docker socket access

Alloy needs access to `/var/run/docker.sock` to discover containers and read their logs. Check that the socket exists:

```bash
ls -l /var/run/docker.sock
```

The lab task ran as root, which allowed it to access the socket. Docker socket access is highly privileged and should be restricted to trusted workloads.

## Loki startup and retention configuration

An earlier Loki configuration enabled retention without configuring the required `compactor.delete-request-store`. Loki failed to start with a configuration error. The working lab setup removed `retention_enabled: true`. If retention is required, configure the deletion request store and compactor settings supported by the deployed Loki version.

Check readiness:

```bash
curl http://172.18.49.163:3100/ready
```

Inspect Loki allocation logs if it does not return `ready`.

## Prometheus targets are DOWN

1. Open `http://172.18.49.163:9090/targets`.
2. Check the target's reported error.
3. Confirm the target service is running in Nomad.
4. Test the endpoint from the relevant network context.
5. Check the scrape target IP and port in `prometheus/prometheus.yml`.
6. Update the IP if the WSL address changed.

## Grafana data source connection problems

Check that the Prometheus and Loki URLs in `grafana/provisioning/datasources/datasources.yml` are reachable from Grafana's container network. A URL that works in the host browser may not work from another container.

Verify Grafana health:

```bash
curl http://172.18.49.163:3000/api/health
```

## Node Exporter duplicate filesystem metrics

During the WSL lab, Node Exporter logged duplicate filesystem metric errors for some mount information, including entries associated with `/run/user` and `tmpfs`. This was not resolved as part of the completed logging integration. Investigate separately if filesystem metrics are incomplete or unreliable; do not describe this issue as fixed.

## Nginx logs do not appear in Grafana

1. Generate requests:

```bash
for i in {1..10}; do
  curl -s -o /dev/null http://172.18.49.163:8080
done
```

2. Confirm Alloy is running: `nomad job status alloy`.
3. Check Alloy allocation logs.
4. Confirm Loki is ready.
5. In Grafana Explore, select Loki and query:

```logql
{job="docker"}
```

To isolate Nginx GET requests made by curl:

```logql
{job="docker", container=~".*nginx.*"} |= "\\\"GET " |= "curl/"
```

The `container` label depends on Alloy relabeling. If no results appear, inspect the actual labels in Loki and adjust the selector.
