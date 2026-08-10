data "google_sql_database_instance" "instance" {
    for_each = var.cloud_sql_database_settings

    name    = each.value["instance_name"]
    project = each.value["project_id"]
}