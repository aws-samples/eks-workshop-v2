output "environment" {
  description = "Evaluated by the IDE shell"
  value       = try(module.lab.environment, "")
}
