# ============================================================
# Variables - Cloud SQL Module
# ============================================================

# ---- Projeto & Região ----
variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "region" {
  description = "Região principal da instância"
  type        = string
  default     = "us-central1"
}

# ---- Instância ----
variable "instance_name" {
  description = "Nome da instância Cloud SQL"
  type        = string
}

variable "database_version" {
  description = "Versão do banco de dados"
  type        = string
  default     = "POSTGRES_15"
  validation {
    condition     = contains(["POSTGRES_15", "POSTGRES_14", "MYSQL_8_0", "SQLSERVER_2019_STANDARD"], var.database_version)
    error_message = "Versão de banco de dados não suportada."
  }
}

variable "tier" {
  description = "Tipo de máquina (ex: db-custom-4-15360, db-n1-standard-4)"
  type        = string
  default     = "db-custom-4-15360"
}

variable "availability_type" {
  description = "REGIONAL = HA com failover automático | ZONAL = sem HA"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "ZONAL"], var.availability_type)
    error_message = "Deve ser REGIONAL ou ZONAL."
  }
}

variable "deletion_protection" {
  description = "Proteção contra deleção acidental"
  type        = bool
  default     = true
}

# ---- Disco ----
variable "disk_type" {
  description = "Tipo de disco: PD_SSD ou PD_HDD"
  type        = string
  default     = "PD_SSD"
}

variable "disk_size" {
  description = "Tamanho inicial do disco em GB"
  type        = number
  default     = 100
}

variable "disk_autoresize_limit" {
  description = "Limite máximo de autoresize em GB (0 = sem limite)"
  type        = number
  default     = 500
}

# ---- Backup ----
variable "backup_start_time" {
  description = "Horário de início do backup (HH:MM)"
  type        = string
  default     = "03:00"
}

variable "backup_location" {
  description = "Região onde os backups serão armazenados"
  type        = string
  default     = "us"
}

variable "retained_backups" {
  description = "Número de backups automáticos retidos"
  type        = number
  default     = 30
}

variable "transaction_log_retention_days" {
  description = "Dias de retenção dos transaction logs (PITR)"
  type        = number
  default     = 7
}

# ---- Rede ----
variable "vpc_network_id" {
  description = "Self-link da VPC onde a instância será conectada"
  type        = string
}

variable "authorized_networks" {
  description = "Lista de redes autorizadas (usar apenas quando necessário)"
  type = list(object({
    name = string
    cidr = string
  }))
  default = []
}

# ---- Manutenção ----
variable "maintenance_window_day" {
  description = "Dia da semana para manutenção (1=Segunda, 7=Domingo)"
  type        = number
  default     = 7 # Domingo
}

variable "maintenance_window_hour" {
  description = "Hora UTC para janela de manutenção (0-23)"
  type        = number
  default     = 4
}

# ---- Databases & Usuários ----
variable "databases" {
  description = "Lista de databases a criar"
  type        = list(string)
  default     = []
}

variable "db_users" {
  description = "Mapa de usuários do banco"
  type = map(object({
    password = string
  }))
  default   = {}
  sensitive = true
}

# ---- Read Replicas ----
variable "read_replica_count" {
  description = "Número de read replicas"
  type        = number
  default     = 0
}

variable "read_replica_region" {
  description = "Região das replicas (null = mesma região da primary)"
  type        = string
  default     = null
}

variable "read_replica_tier" {
  description = "Tier das replicas (null = mesmo da primary)"
  type        = string
  default     = null
}

# ---- Flags do banco ----
variable "database_flags" {
  description = "Flags de configuração do banco de dados"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# ---- IAM ----
variable "create_proxy_service_account" {
  description = "Criar service account para Cloud SQL Auth Proxy"
  type        = bool
  default     = true
}

# ---- Labels ----
variable "labels" {
  description = "Labels aplicadas aos recursos"
  type        = map(string)
  default     = {}
}
