
job "prometheus" {
  datacenters = ["dc1"]
  type        = "service"

  group "monitoring" {
    count = 1

    network {
      port "prometheus" {
        static = 9090
        to     = 9090
      }
    }

    service {
      name = "prometheus"
      port = "prometheus"

      check {
        name     = "prometheus-health"
        type     = "http"
        path     = "/-/healthy"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:v3.2.1"
        ports = ["prometheus"]

        volumes = [
  "/home/kwamzzy/projects/nomad-observability-stack/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml"
]

        args = [
          "--config.file=/etc/prometheus/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.enable-lifecycle"
        ]
      }

      resources {
        cpu    = 300
        memory = 512
      }
    }
  }
}
