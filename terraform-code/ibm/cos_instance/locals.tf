# Flatten necessario porque cada instancia pode conceder acesso a N access
# groups por papel (Manager/Writer/Reader) - mesmo padrao ja usado no modulo
# de IAM do Dataplex e no cmek_key_bindings do spanner_database.
locals {
  manager_bindings = flatten([
    for k, v in var.cos_instance_settings : [
      for ag in v.iam_bindings.managers : { instance_key = k, access_group_id = ag }
    ]
  ])
  manager_bindings_map = { for item in local.manager_bindings : "${item.instance_key}-${item.access_group_id}" => item }

  writer_bindings = flatten([
    for k, v in var.cos_instance_settings : [
      for ag in v.iam_bindings.writers : { instance_key = k, access_group_id = ag }
    ]
  ])
  writer_bindings_map = { for item in local.writer_bindings : "${item.instance_key}-${item.access_group_id}" => item }

  reader_bindings = flatten([
    for k, v in var.cos_instance_settings : [
      for ag in v.iam_bindings.readers : { instance_key = k, access_group_id = ag }
    ]
  ])
  reader_bindings_map = { for item in local.reader_bindings : "${item.instance_key}-${item.access_group_id}" => item }
}
