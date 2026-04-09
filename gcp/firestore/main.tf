# ============================================================
# Firestore Database Module
# ============================================================

resource "google_firestore_database" "database" {
  for_each = var.firestore_settings

  name        = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  location_id = each.value.region
  project     = each.value.project_id
  type        = each.value.type

  # Apenas prd tem concurrency mode otimista
  concurrency_mode = terraform.workspace == "prd" ? "OPTIMISTIC" : "PESSIMISTIC"

  # Apenas prd tem point-in-time recovery
  point_in_time_recovery_enablement = terraform.workspace == "prd" ? "POINT_IN_TIME_RECOVERY_ENABLED" : "POINT_IN_TIME_RECOVERY_DISABLED"

  # Delete protection apenas em prd
  delete_protection_state = terraform.workspace == "prd" ? "DELETE_PROTECTION_ENABLED" : "DELETE_PROTECTION_DISABLED"

  deletion_policy = terraform.workspace == "prd" ? "DELETE" : "ABANDON"

  # --------------------------------------------------------
  # KMS - usa chave existente (opcional)
  # --------------------------------------------------------
  dynamic "cmek_config" {
    for_each = each.value.kms_key_name != null ? [1] : []
    content {
      kms_key_name = data.google_kms_crypto_key.firestore_key[each.key].id
    }
  }
}
