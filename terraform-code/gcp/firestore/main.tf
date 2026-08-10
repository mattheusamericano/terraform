# ============================================================
# Firestore Database Module
# ============================================================

resource "google_firestore_database" "database" {
  for_each = var.firestore_settings

  name        = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  location_id = each.value["region"]
  project     = each.value["project_id"]
  type        = each.value["type"]

  # Apenas prd tem concurrency mode otimista
  concurrency_mode  = terraform.workspace == "prd" ? "OPTIMISTIC" : "PESSIMISTIC"
  
  #database_edition é suportado apenas para o type "FIRESTORE_NATIVE"
  database_edition  = each.value.type == "FIRESTORE_NATIVE" ? (
    terraform.workspace == "prd" ? "ENTERPRISE" : "STANDARD"
  ) : null

  # Apenas prd tem point-in-time recovery
  point_in_time_recovery_enablement = terraform.workspace == "prd" ? "POINT_IN_TIME_RECOVERY_ENABLED" : "POINT_IN_TIME_RECOVERY_DISABLED"
  
  #Desabilitando o delete protection para a esteira conseguir gerenciar o recurso fim a fim
  delete_protection_state = "DELETE_PROTECTION_DISABLED"
  deletion_policy = "DELETE"

  # --------------------------------------------------------
  # KMS - usa chave existente (opcional)
  # --------------------------------------------------------
  dynamic "cmek_config" {
    for_each = each.value.kms_keyring != null ? [1] : []
    content {
      kms_key_name = data.google_kms_crypto_key.firestore_key[each.key].id
    }
  }
}