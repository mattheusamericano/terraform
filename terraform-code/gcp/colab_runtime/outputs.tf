output "colab_runtime_template_ids" {
  description = "ID de cada template de runtime criado, indexado pela mesma chave de var.colab_runtime_template_settings."
  value = {
    for key, template in google_colab_runtime_template.runtime-template : key => template.id
  }
}

output "colab_runtime_template_names" {
  description = "Nome (name) de cada template de runtime criado, indexado pela mesma chave de var.colab_runtime_template_settings."
  value = {
    for key, template in google_colab_runtime_template.runtime-template : key => template.name
  }
}

output "colab_runtime_template_kms_key_names" {
  description = "kms_key_name de cada template, indexado pela mesma chave de var.colab_runtime_template_settings. null quando o template daquela chave não usa CMEK."
  value       = local.colab_runtime_template_kms_key_names
}
