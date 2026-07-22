cos_bucket_settings = {
  cache_decisao = {
    sigla         = "sipml"
    instance_crn  = "crn:v1:bluemix:public:cloud-object-storage:global:a/1234567890abcdef1234567890abcdef:z9y8x7w6-v5u4-3210-tsrq-ponmlkjihgfe::"
    instance_guid = "z9y8x7w6-v5u4-3210-tsrq-ponmlkjihgfe"

    location_type = "region"
    location      = "br-sao"
    storage_class = "standard"
    endpoint_type = "private"

    object_versioning_enabled = true

    retention_rule = {
      default = 30
      maximum = 365
      minimum = 1
    }

    iam_bindings = {
      managers = ["AccessGroupId-1111aaaa-2222-bbbb-3333-cccc4444dddd"]
      writers  = ["AccessGroupId-5555eeee-6666-ffff-7777-gggg8888hhhh"]
      readers  = ["AccessGroupId-9999iiii-0000-jjjj-1111-kkkk2222llll"]
    }
  }

  auditoria_transacional = {
    sigla         = "sipml"
    instance_crn  = "crn:v1:bluemix:public:cloud-object-storage:global:a/1234567890abcdef1234567890abcdef:z9y8x7w6-v5u4-3210-tsrq-ponmlkjihgfe::"
    instance_guid = "z9y8x7w6-v5u4-3210-tsrq-ponmlkjihgfe"

    location_type = "cross_region"
    location      = "us"
    storage_class = "vault"

    object_lock  = true
    force_delete = false

    retention_rule = {
      default   = 365
      maximum   = 3650
      minimum   = 365
      permanent = false
    }

    activity_tracking = {
      read_data_events  = true
      write_data_events = true
    }
  }
}
