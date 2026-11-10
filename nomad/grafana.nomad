variable "grafana_admin_password" {
  type      = string
  sensitive = true
}

job "grafana" {
  datacenters = ["dc1"]
  type        = "service"

  group "monitoring" {
    count = 1

    network {
      port "http" {
        static = 3000
        to     = 3000
      }
    }

    service {
      name = "grafana"
      port = "http"

      check {
        name     = "grafana-health"
        type     = "http"
        path     = "/api/health"
        interval = "10s"
        timeout  = "3s"
      }
    }

    task "grafana" {
      driver = "docker"

      env {
        GF_SECURITY_ADMIN_USER     = "admin"
        GF_SECURITY_ADMIN_PASSWORD = var.grafana_admin_password
        GF_USERS_ALLOW_SIGN_UP     = "false"
      }

      config {
        image = "grafana/grafana:11.5.2"
        ports = ["http"]

        volumes = [
          "/home/kwamzzy/projects/nomad-observability-stack/grafana/provisioning:/etc/grafana/provisioning"
        ]
      }

      resources {
        cpu    = 300
        memory = 512
      }
    }
  }
}
