# Acesso restrito a ESTE bucket - resource_type "bucket" + resource com o nome
# real do bucket, escopado dentro da instancia COS (resource_instance_id = guid).
resource "ibm_iam_access_group_policy" "manager" {
  for_each = local.manager_bindings_map

  access_group_id = each.value.access_group_id
  roles           = ["Manager"]

  resources {
    service              = "cloud-object-storage"
    resource_instance_id = var.cos_bucket_settings[each.value.bucket_key].instance_guid
    resource_type        = "bucket"
    resource             = ibm_cos_bucket.this[each.value.bucket_key].bucket_name
  }
}

resource "ibm_iam_access_group_policy" "writer" {
  for_each = local.writer_bindings_map

  access_group_id = each.value.access_group_id
  roles           = ["Writer"]

  resources {
    service              = "cloud-object-storage"
    resource_instance_id = var.cos_bucket_settings[each.value.bucket_key].instance_guid
    resource_type        = "bucket"
    resource             = ibm_cos_bucket.this[each.value.bucket_key].bucket_name
  }
}

resource "ibm_iam_access_group_policy" "reader" {
  for_each = local.reader_bindings_map

  access_group_id = each.value.access_group_id
  roles           = ["Reader"]

  resources {
    service              = "cloud-object-storage"
    resource_instance_id = var.cos_bucket_settings[each.value.bucket_key].instance_guid
    resource_type        = "bucket"
    resource             = ibm_cos_bucket.this[each.value.bucket_key].bucket_name
  }
}
