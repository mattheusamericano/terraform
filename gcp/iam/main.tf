###### CONSULTAR SE VAMOS DAR ESSE ACESSO #########
# Permite CRIAR buckets (e administrar Storage) para o grupo RISCFAB
#resource "google_project_iam_member" "risccrvar_storage_admin" {
#  project = var.project_id
#  role    = "roles/storage.admin"
#  member  = "group:G_GCP_RISCCRVAR_DTSC@corp.caixa.gov.br"
#}
# resource "google_project_iam_member" "riscfab_storage_admin" {
  # project = var.project_id
  # role    = "roles/storage.admin"
  # member  = "group:G_GCP_RISCFAB_DTSC@corp.caixa.gov.br"
# }
