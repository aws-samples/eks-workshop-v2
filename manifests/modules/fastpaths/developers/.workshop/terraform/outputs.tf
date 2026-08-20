output "environment_variables" {
  description = "Environment variables to be added to the IDE shell"
  value       = try(module.preprovision[0].environment_variables, {})
}
