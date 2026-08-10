data "google_compute_network" "vpc" {
    for_each = var.cloud_sql_instance_settings
    
    name        = each.value.name_vpc_shared
    project     = each.value.network_project_id
}

data "google_kms_key_ring" "keyring" {
    for_each = var.cloud_sql_instance_settings

    name        = each.value["key_ring"]
    location    = each.value["region"]
    project     = each.value["kms_project_id"]
}

data "google_kms_crypto_key" "keycrypto" {
    for_each = var.cloud_sql_instance_settings

    name        = each.value["key_crypto"]
    key_ring    = data.google_kms_key_ring.keyring[each.key].id

}
