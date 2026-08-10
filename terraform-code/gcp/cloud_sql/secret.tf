resource "google_secret_manager_secret" "sql_admin_password" {
    for_each = var.cloud_sql_instance_settings

    secret_id   = "${each.key}-localadmin-password-${each.value.sigla}-${terraform.workspace}"
    project     = each.value["project_id"]
    labels      = each.value["labels"]

    replication {
      user_managed {
        replicas {
            location = each.value["region"]
        }  
      }
    }
}

resource "google_secret_manager_secret_version" "sql_admin_password_version" {
    for_each = var.cloud_sql_instance_settings

    secret          = google_secret_manager_secret.sql_admin_password[each.key].id
    secret_data     = local.admin_password

    lifecycle {
        ignore_changes = [secret_data]
    } 
}