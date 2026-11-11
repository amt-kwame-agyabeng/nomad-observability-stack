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

telemetry {
  prometheus_metrics          = true
  publish_allocation_metrics  = true
  publish_node_metrics        = true
}