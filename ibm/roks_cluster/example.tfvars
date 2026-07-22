roks_cluster_settings = {
  hub_decision_broker = {
    sigla             = "sipml"
    resource_group_id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6" # dedicado a este cluster - ver Observacoes no README
    vpc_id            = "r010-1a2b3c4d-5e6f-7890-abcd-ef1234567890"

    flavor       = "bx2.4x16"
    kube_version = "4.15_openshift"
    worker_count = 2

    zones = [
      { name = "br-sao-1", subnet_id = "0717-1a2b3c4d-0001-4aaa-bbbb-000000000001" },
      { name = "br-sao-2", subnet_id = "0717-1a2b3c4d-0002-4aaa-bbbb-000000000002" },
      { name = "br-sao-3", subnet_id = "0717-1a2b3c4d-0003-4aaa-bbbb-000000000003" },
    ]

    cos_instance_crn = "crn:v1:bluemix:public:cloud-object-storage:global:a/1234567890abcdef1234567890abcdef:z9y8x7w6-v5u4-3210-tsrq-ponmlkjihgfe::"

    disable_public_service_endpoint = true

    tags = ["camada:hub", "uso:decision-broker"]
    labels = {
      camada = "hub"
    }

    iam_bindings = {
      managers  = ["AccessGroupId-1111aaaa-2222-bbbb-3333-cccc4444dddd"]
      operators = ["AccessGroupId-5555eeee-6666-ffff-7777-gggg8888hhhh"]
      viewers   = []
    }
  }
}
