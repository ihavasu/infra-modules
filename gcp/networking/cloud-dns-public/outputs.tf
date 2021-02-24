output "domain" {
  description = "The DNS zone domain."
  value       = module.cloud_dns_public.domain
}

output "name" {
  description = "The DNS zone name."
  value       = module.cloud_dns_public.name
}

output "name_servers" {
  description = "The DNS zone name servers."
  value       = module.cloud_dns_public.name_servers
}
