output "roles" {
  value       = { for role in local.roles_set : role.name => random_password.default[role.name].result }
  sensitive   = true
  description = "A map of role name per password."
}

output "databases" {
  value       = [for db in postgresql_role.default : db.name]
  sensitive   = true
  description = "A list of databases."
}
