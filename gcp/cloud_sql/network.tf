#resource "google_compute_global_address" "private_ip_range" {
#  for_each = var.cloud_sql_instance_settings

#  name              = "pvt-${each.key}-${each.value.sigla}-${terraform.workspace}"
#  purpose           = "VPC_PEERING"
#  address_type      = "INTERNAL"
#  address_type      = "10.250.16.0"
#  prefix_length     = 24
#  network           = "projects/${each.value.network_project_id}/global/networks/${each.value.name_vpc_shared}"
#  project           = each.value["network_project_id"]
#}

#resource "google_service_networking_connection" "private_vpc_connection" {
#  for_each = var.cloud_sql_instance_settings
  
#  network                 = "projects/${each.value.network_project_id}/global/networks/${each.value.name_vpc_shared}"
#  service                 = "servicenetworking.googleapis.com"
#  reserved_peering_ranges = ["private-sigrm-workpool"]
  
#}