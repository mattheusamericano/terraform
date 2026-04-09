firestore_settings = {
  app = {
    project_id  = "prj-risco-sigrm-prd"
    region      = "southamerica-east1"
    sigla       = "sigrm"
    type        = "FIRESTORE_NATIVE"

    # Com KMS
    kms_project_id   = "prj-hsm-services-prd"
    kms_keyring_name = "infraNPRDring"
    kms_key_name     = "infraNPRDSYMAES256hsm001"

    group_writer  = "G_GCP_COE_NUVEM@corp.caixa.gov.br"
    groups_reader = [
      "G_GCP_ANALYTICS@corp.caixa.gov.br"
    ]

    labels = {
      team = "platform"
      app  = "sigrm"
    }
  }
}
