roks_worker_pool_settings = {
  gpu_workloads = {
    cluster_id        = "bnqrqtqd0b0hjqfsg0jg" # module.roks_cluster.cluster_ids["hub_decision_broker"]
    vpc_id            = "r010-1a2b3c4d-5e6f-7890-abcd-ef1234567890"
    resource_group_id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"

    flavor       = "gx2.8x64.l4"
    worker_count = 1

    zones = [
      { name = "br-sao-1", subnet_id = "0717-1a2b3c4d-0001-4aaa-bbbb-000000000001" },
    ]

    labels = {
      workload = "gpu"
    }

    taints = [
      { key = "workload", value = "gpu", effect = "NoSchedule" },
    ]
  }
}
