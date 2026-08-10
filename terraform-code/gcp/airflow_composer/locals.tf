locals {
    kms_unique_bindings = {
        for k, v in var.composer_settings :
        "${v.project_id}||${v.kms_project_id}||${v.region}||${v.key_ring}||${v.key_crypto}" => v...
    }

    kms_unique_bindings_flat = {
        for key, val in local.kms_unique_bindings :
        key => val[0]
    }
    unique_projects = {
        for k, v in var.composer_settings :
        v.project_id => v...
    }

    unique_projects_flat = {
        for key, val in local.unique_projects :
        key => val[0]
    }    
}
