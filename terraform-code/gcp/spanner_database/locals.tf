# Flatten justificado: um database pode ter 0, 1 (região única) ou N chaves
# (multi-região), então não dá pra expressar isso com um for_each simples
# sobre var.spanner_database_settings — é o mesmo motivo que levou o
# dataplex-iam a existir como módulo separado.
locals {
  cmek_key_bindings = flatten([
    for db_key, db in var.spanner_database_settings : [
      for kms_key in(
        db.encryption == null ? [] : (
          length(db.encryption.kms_key_names) > 0
          ? db.encryption.kms_key_names
          : (db.encryption.kms_key_name != null ? [db.encryption.kms_key_name] : [])
        )
        ) : {
        db_key  = db_key
        kms_key = kms_key
      } if db.encryption != null && db.encryption.grant_kms_iam
    ]
  ])

  cmek_key_bindings_map = {
    for item in local.cmek_key_bindings : "${item.db_key}-${item.kms_key}" => item
  }
}
