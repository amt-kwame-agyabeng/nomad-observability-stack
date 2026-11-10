
job "node-exporter" {
  datacenters = ["dc1"]
  type        = "service"

  group "monitoring" {
    count = 1

    network {
      port "metrics" {
        static = 9100
        to     = 9100
      }
    }

    service {
      name = "node-exporter"
      port = "metrics"

      check {
        name     = "node-exporter-health"
        type     = "http"
        path     = "/metrics"
        interval = "15s"
        timeout  = "3s"
      }
    }

    task "node-exporter" {
      driver = "docker"

      config {
        image = "prom/node-exporter:v1.9.1"
        ports = ["metrics"]

        mount {
          type     = "bind"
          source   = "/proc"
          target   = "/host/proc"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "/sys"
          target   = "/host/sys"
          readonly = true
        }

        mount {
          type     = "bind"
          source   = "/"
          target   = "/host/root"
          readonly = true
        }

        args = [
          "--path.procfs=/host/proc",
          "--path.sysfs=/host/sys",
          "--path.rootfs=/host/root",
          "--web.listen-address=:9100"
        ]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
