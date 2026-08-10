# Flatten necessario porque cada bucket pode conceder acesso a N access groups
# por papel (Manager/Writer/Reader) - mesmo padrao usado no modulo cos_instance.
locals {
  manager_bindings = flatten([
    for k, v in var.cos_bucket_settings : [
      for ag in v.iam_bindings.managers : { bucket_key = k, access_group_id = ag }
    ]
  ])
  manager_bindings_map = { for item in local.manager_bindings : "${item.bucket_key}-${item.access_group_id}" => item }

  writer_bindings = flatten([
    for k, v in var.cos_bucket_settings : [
      for ag in v.iam_bindings.writers : { bucket_key = k, access_group_id = ag }
    ]
  ])
  writer_bindings_map = { for item in local.writer_bindings : "${item.bucket_key}-${item.access_group_id}" => item }

  reader_bindings = flatten([
    for k, v in var.cos_bucket_settings : [
      for ag in v.iam_bindings.readers : { bucket_key = k, access_group_id = ag }
    ]
  ])
  reader_bindings_map = { for item in local.reader_bindings : "${item.bucket_key}-${item.access_group_id}" => item }
}
