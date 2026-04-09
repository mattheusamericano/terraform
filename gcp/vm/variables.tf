variable "vm_settings" {
  description = "Map de configurações das VMs"
  type = map(object({
    sigla      = string
    project_id = string
    zone       = string

    # --------------------------------------------------------
    # Compute
    # --------------------------------------------------------
    machine_type = string

    # --------------------------------------------------------
    # Boot disk
    # image           = imagem pública (ex: "debian-cloud/debian-12")
    # image_self_link = imagem personalizada (mutuamente exclusivo com image)
    # --------------------------------------------------------
    boot_disk = object({
      image           = optional(string, null)
      image_self_link = optional(string, null)
      size            = number
      type            = optional(string, "pd-balanced") # pd-standard | pd-balanced | pd-ssd
    })

    # --------------------------------------------------------
    # Networking
    # --------------------------------------------------------
    network_name      = string
    subnetwork_name   = string
    subnetwork_region = string
    enable_public_ip  = optional(bool, false)
    network_tags      = optional(list(string), [])

    # --------------------------------------------------------
    # Service Account
    # --------------------------------------------------------
    service_account_email = optional(string, null)
    scopes                = optional(list(string), ["cloud-platform"])

    # --------------------------------------------------------
    # Metadata / Startup Script
    # --------------------------------------------------------
    startup_script = optional(string, null)
    metadata       = optional(map(string), {})

    # --------------------------------------------------------
    # Stop Schedule (opcional)
    # Desliga a VM automaticamente no horário configurado (cron)
    # O start é feito manualmente pelo técnico quando necessário
    # ex: schedule = "0 20 * * *" → desliga todo dia às 20h
    # --------------------------------------------------------
    stop_schedule = optional(object({
      schedule = string                               # cron expression
      timezone = optional(string, "America/Sao_Paulo")
    }), null)

    # --------------------------------------------------------
    # KMS (opcional)
    # --------------------------------------------------------
    kms_key_self_link = optional(string, null)

    # --------------------------------------------------------
    # Labels
    # --------------------------------------------------------
    labels = optional(map(string), {})
  }))
}
