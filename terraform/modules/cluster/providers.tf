terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = "1.31.1"
    }
  }

  required_version = "<= 1.2.9"
}