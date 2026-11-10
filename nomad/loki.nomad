job "loki" {
  datacenters = ["dc1"]
  type        = "service"

  group "logging" {
    count = 1

    network {
      port "http" {
        static = 3100
        to     = 3100
      }
    }

    service {
      name = "loki"
      port = "http"

      check {
        name     = "loki-ready"
        type     = "http"
        path     = "/ready"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/loki:3.4.2"
        ports = ["http"]

        volumes = [
          "/home/kwamzzy/projects/nomad-observability-stack/loki/loki-config.yml:/etc/loki/local-config.yaml"
        ]

        args = [
          "-config.file=/etc/loki/local-config.yaml"
        ]
      }

      resources {
        cpu    = 300
        memory = 512
      }
    }
  }
}
