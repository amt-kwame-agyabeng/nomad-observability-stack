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
