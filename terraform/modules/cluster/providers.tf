terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = "1.30.0"
    }
  }

  required_version = "<= 1.2.9"
}