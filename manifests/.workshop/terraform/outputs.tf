output "environment" {
  value = try(module.lab.environment, "")
}
