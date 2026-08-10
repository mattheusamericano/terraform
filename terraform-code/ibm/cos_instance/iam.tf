# Autoriza esta instancia COS a usar chaves de criptografia de uma instancia
# Key Protect/HPCS existente (equivalente ao cryptoKeyEncrypterDecrypter do GCP).
resource "ibm_iam_authorization_policy" "cos_kms" {
  for_each = { for k, v in var.cos_instance_settings : k => v if v.kms_instance_guid != null }

  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = ibm_resource_instance.this[each.key].guid
  target_service_name         = each.value.kms_service_name
  target_resource_instance_id = each.value.kms_instance_guid
  roles                       = ["Reader"]
  description                 = "Permite que a instancia COS ${each.key} use chaves do ${each.value.kms_service_name}"
}

# Acesso em nivel de instancia (valido para todos os buckets dela)
resource "ibm_iam_access_group_policy" "manager" {
  for_each = local.manager_bindings_map

  access_group_id = each.value.access_group_id
  roles           = ["Manager"]

  resources {
    service              = "cloud-object-storage"
    resource_instance_id = ibm_resource_instance.this[each.value.instance_key].guid
  }
}

resource "ibm_iam_access_group_policy" "writer" {
  for_each = local.writer_bindings_map

  access_group_id = each.value.access_group_id
  roles           = ["Writer"]

  resources {
    service              = "cloud-object-storage"
    resource_instance_id = ibm_resource_instance.this[each.value.instance_key].guid
  }
}

resource "ibm_iam_access_group_policy" "reader" {
  for_each = local.reader_bindings_map

  access_group_id = each.value.access_group_id
  roles           = ["Reader"]

  resources {
    service              = "cloud-object-storage"
    resource_instance_id = ibm_resource_instance.this[each.value.instance_key].guid
  }
}
