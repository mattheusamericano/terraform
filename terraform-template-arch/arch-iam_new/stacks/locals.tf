locals {
  common_labels = {
    "Ambiente"      = "__environment__"
    "EquipeInfra"   = "CESTI35"
    "EquipeSolucao" = "__sigla__"
    "Solucao"       = "__sigla__"
    "Provimento"    = "Terraform"
    "Workload"      = "__sigla__"
  }

  # As roles por perfil (ML Engineer/Data Scientist/Data Engineer) e a
  # distinção modelagem x inferência não vivem mais aqui — foram movidas para
  # dentro do módulo iam (ml_ops_profiles.tf), que é quem monta os grants
  # a partir de var.project_type e dos grupos repassados em main.tf.
}
