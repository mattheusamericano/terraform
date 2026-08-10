resource "google_storage_bucket" "bucket" {
  for_each = var.bucket_settings

  name                            = "${each.key}-${each.value.sigla}-${terraform.workspace}"
  project                         = each.value["project_id"]
  location                        = each.value["region"]
  storage_class                   = each.value["storage_class"]
  uniform_bucket_level_access     = true
  labels                          = each.value["labels"]
  force_destroy                   = true
  public_access_prevention        = "enforced"

  encryption {
    default_kms_key_name = "projects/${each.value.kms_project_id}/locations/${each.value.region}/keyRings/${each.value.kms_key_name}/cryptoKeys/${each.value.kms_key_crypto}" 
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      num_newer_versions = 1
      with_state         = "ARCHIVED"
    }
  }

}