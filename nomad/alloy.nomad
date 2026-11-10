job "alloy" {
  datacenters = ["dc1"]
  type        = "service"

  group "alloy" {
    count = 1

    network {
      mode = "host"
    }

    task "alloy" {
      driver = "docker"

      env {
        ALLOY_CONFIG_REVISION = "2"
      }

      config {
        image        = "grafana/alloy:latest"
        network_mode = "host"

        args = [
          "run",
          "--server.http.listen-addr=0.0.0.0:12345",
          "--storage.path=/var/lib/alloy/data",
          "/etc/alloy/config.alloy"
        ]

        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock",
          "/home/kwamzzy/projects/nomad-observability-stack/grafana/config.alloy:/etc/alloy/config.alloy"
        ]
      }

      resources {
        cpu    = 300
        memory = 512
      }
    }
  }
}
