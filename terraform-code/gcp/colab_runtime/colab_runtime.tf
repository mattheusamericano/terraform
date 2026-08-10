#resource "google_colab_runtime" "runtime" {
#  for_each = var.colab_runtime_template_settings
  
#  name              = "${each.value.accelerator_type != "" && each.value.accelerator_type != null ? "gpu-" : ""}${each.value.runtime_name}-${each.value.sigla}-${terraform.workspace}"
#  location          = each.value["region"]

#  notebook_runtime_template_ref {
#    notebook_runtime_template = google_colab_runtime_template.runtime-template[each.key].id
#  }

#  display_name      = "${each.value.accelerator_type != "" && each.value.accelerator_type != null ? "gpu-" : ""}${each.value.runtime_name}-${each.value.sigla}-${terraform.workspace}"
  #runtime_user      = each.value["runtime_user"]
#  description       = "Runtime created by Terraform"

#  desired_state     = "ACTIVE"

#  auto_upgrade      = true

#  depends_on = [
#    google_colab_runtime_template.runtime-template
#  ]
#}