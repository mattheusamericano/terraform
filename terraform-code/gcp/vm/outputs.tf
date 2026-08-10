output "instance_ids" {
  description = "Map de nome da VM para seu ID"
  value       = { for k, v in google_compute_instance.vm : k => v.id }
}

output "instance_self_links" {
  description = "Map de nome da VM para seu self-link"
  value       = { for k, v in google_compute_instance.vm : k => v.self_link }
}

output "internal_ips" {
  description = "Map de nome da VM para seu IP interno"
  value       = { for k, v in google_compute_instance.vm : k => v.network_interface[0].network_ip }
}

output "external_ips" {
  description = "Map de nome da VM para seu IP externo (null se não houver)"
  value = {
    for k, v in google_compute_instance.vm : k =>
    length(v.network_interface[0].access_config) > 0 ? v.network_interface[0].access_config[0].nat_ip : null
  }
}

output "instance_names" {
  description = "Map de chave para nome completo da VM"
  value       = { for k, v in google_compute_instance.vm : k => v.name }
}
