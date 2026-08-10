cos_instance_settings = {
  hub_decision_broker = {
    sigla             = "sipml"
    resource_group_id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
    plan              = "standard"

    tags = ["camada:hub", "uso:decision-broker"]

    # Opcional: autoriza a instancia a usar uma chave existente do Key Protect
    kms_service_name  = "kms"
    kms_instance_guid = "z9y8x7w6-v5u4-3210-tsrq-ponmlkjihgfe"

    iam_bindings = {
      managers = ["AccessGroupId-1111aaaa-2222-bbbb-3333-cccc4444dddd"]
      writers  = ["AccessGroupId-5555eeee-6666-ffff-7777-gggg8888hhhh"]
      readers  = []
    }
  }
}
