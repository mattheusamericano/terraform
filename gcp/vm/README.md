# vm

Módulo Terraform responsável por provisionar instâncias de Compute Engine (`google_compute_instance`) no GCP, com suporte opcional a disco de boot customizado ou público, IP público, criptografia via KMS (Confidential Computing), Service Account dedicada, tags de rede e agendamento automático de desligamento (stop schedule). Todo o módulo é orientado a um único mapa de configuração (`var.vm_settings`), permitindo criar N VMs com características distintas em uma única aplicação.

## Recursos criados

- `google_compute_instance.vm` — cria a instância de Compute Engine propriamente dita, para cada chave do mapa `var.vm_settings`.
- `google_compute_resource_policy.stop_schedule` — cria uma política de agendamento (`instance_schedule_policy`) para desligar a VM automaticamente em um horário definido via expressão cron. Criado apenas para as VMs cujo `stop_schedule` não é `null`.

## Data sources utilizados

- `data.google_compute_network.vpc` — resolve a VPC existente (`network_name`) onde a VM será conectada.
- `data.google_compute_subnetwork.subnet` — resolve a sub-rede existente (`subnetwork_name`/`subnetwork_region`) onde a VM será conectada.

## Como usar

```hcl
module "vm" {
  source = "./gcp/vm"

  vm_settings = {
    "vm-app-01" = {
      sigla        = "sqa"
      project_id   = "meu-projeto-gcp"
      zone         = "us-central1-a"
      machine_type = "e2-standard-4"

      boot_disk = {
        image = "debian-cloud/debian-12"
        size  = 50
        type  = "pd-balanced"
      }

      network_name       = "vpc-shared"
      subnetwork_name    = "subnet-app"
      subnetwork_region  = "us-central1"
      enable_public_ip   = false
      network_tags       = ["app", "ssh-internal"]

      service_account_email = "sa-app@meu-projeto-gcp.iam.gserviceaccount.com"
      scopes                 = ["cloud-platform"]

      startup_script = "#!/bin/bash\necho 'hello world'"
      metadata = {
        ambiente = "producao"
      }

      stop_schedule = {
        schedule = "0 20 * * *"
        timezone = "America/Sao_Paulo"
      }

      kms_key_self_link = "projects/meu-projeto-kms/locations/us-central1/keyRings/anel/cryptoKeys/chave"

      labels = {
        equipe = "dados"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `vm_settings` | Mapa de configurações das VMs. A chave do mapa é usada como parte do nome da instância. Ver estrutura detalhada abaixo. | `map(object({...}))` | — | Sim |

### Estrutura de `vm_settings`

Cada entrada do mapa representa uma VM e aceita os seguintes campos:

| Campo | Tipo | Default | Descrição |
|-------|------|---------|-----------|
| `sigla` | `string` | — | Sufixo de nomenclatura usado no nome final da VM. |
| `project_id` | `string` | — | Projeto onde a VM será criada. |
| `zone` | `string` | — | Zona de disponibilidade da VM. |
| `machine_type` | `string` | — | Tipo de máquina (ex.: `e2-standard-4`). |
| `boot_disk.image` | `optional(string, null)` | `null` | Imagem pública de boot (ex.: `debian-cloud/debian-12`). Mutuamente exclusivo com `image_self_link`. |
| `boot_disk.image_self_link` | `optional(string, null)` | `null` | Self-link de uma imagem customizada. Tem prioridade sobre `image` quando informado. |
| `boot_disk.size` | `number` | — | Tamanho do disco de boot em GB. |
| `boot_disk.type` | `optional(string, "pd-balanced")` | `"pd-balanced"` | Tipo do disco de boot (`pd-standard`, `pd-balanced` ou `pd-ssd`). |
| `network_name` | `string` | — | Nome da VPC existente onde a VM será conectada. |
| `subnetwork_name` | `string` | — | Nome da sub-rede existente. |
| `subnetwork_region` | `string` | — | Região da sub-rede. |
| `enable_public_ip` | `optional(bool, false)` | `false` | Se `true`, adiciona um `access_config` (IP externo, tier PREMIUM) à interface de rede. |
| `network_tags` | `optional(list(string), [])` | `[]` | Tags de rede aplicadas à VM (usadas em firewall rules). |
| `service_account_email` | `optional(string, null)` | `null` | E-mail de uma Service Account existente a ser anexada à VM. Se `null`, o bloco `service_account` não é criado. |
| `scopes` | `optional(list(string), ["cloud-platform"])` | `["cloud-platform"]` | Scopes de OAuth da Service Account anexada à VM. |
| `startup_script` | `optional(string, null)` | `null` | Script de inicialização da VM. Declarado na variável, mas não é utilizado no `main.tf` atual (ver Observações). |
| `metadata` | `optional(map(string), {})` | `{}` | Metadados adicionais da instância. Declarado na variável, mas não é utilizado no `main.tf` atual (ver Observações). |
| `stop_schedule.schedule` | `string` | — | Expressão cron do horário de desligamento automático (ex.: `"0 20 * * *"` desliga às 20h todos os dias). |
| `stop_schedule.timezone` | `optional(string, "America/Sao_Paulo")` | `"America/Sao_Paulo"` | Timezone usado na expressão cron. |
| `kms_key_self_link` | `optional(string, null)` | `null` | Self-link de uma chave KMS. Quando informado, criptografa o disco de boot (`disk_encryption_key`) e habilita Confidential Computing na instância. |
| `labels` | `optional(map(string), {})` | `{}` | Labels aplicadas à VM, mescladas automaticamente com `environment` (workspace) e `managed_by = "terraform"`. |

## Outputs

| Nome | Descrição |
|------|-----------|
| `instance_ids` | Mapa da chave de cada VM para o seu ID (`v.id`). |
| `instance_self_links` | Mapa da chave de cada VM para o seu self-link. |
| `internal_ips` | Mapa da chave de cada VM para o seu IP interno (primeira interface de rede). |
| `external_ips` | Mapa da chave de cada VM para o seu IP externo, ou `null` caso a VM não tenha `access_config` (IP público desabilitado). |
| `instance_names` | Mapa da chave de cada VM para o seu nome completo gerado. |

## Observações

- O nome final da VM (e da política de stop schedule, quando existir) segue o padrão `${chave}-${sigla}-${terraform.workspace}`.
- `stop_schedule` é opcional: a política `google_compute_resource_policy.stop_schedule` só é criada para as VMs cujo campo `stop_schedule` seja diferente de `null` (via `for_each` filtrado). O desligamento é automático conforme o cron configurado; o religamento (`start`) precisa ser feito manualmente.
- Criptografia via KMS (`kms_key_self_link`) é opcional. Quando informada, é aplicada tanto ao disco de boot (`disk_encryption_key`) quanto habilita `confidential_instance_config` (Confidential Computing) na instância.
- IP público (`enable_public_ip`) é opcional e desabilitado por padrão — a interface de rede só recebe `access_config` quando `enable_public_ip = true`.
- A Service Account só é anexada à VM (`service_account` block) quando `service_account_email` é informado; o módulo não cria a Service Account, apenas a referencia.
- Shielded VM (`enable_secure_boot`, `enable_vtpm`, `enable_integrity_monitoring`) é habilitado incondicionalmente para todas as VMs.
- O reinício automático (`automatic_restart`) só é habilitado quando `terraform.workspace == "prd"`; nos demais workspaces fica desabilitado.
- As labels informadas são mescladas com `environment = terraform.workspace` e `managed_by = "terraform"`, então essas duas chaves são sempre sobrescritas pelo módulo independentemente do que for passado em `labels`.
- O `lifecycle.ignore_changes` ignora alterações em `metadata["ssh-keys"]`, evitando que chaves SSH adicionadas manualmente/fora do Terraform gerem drift.
- **Atenção**: os campos `startup_script` e `metadata` estão declarados na variável `vm_settings`, mas não são efetivamente aplicados ao recurso `google_compute_instance.vm` no `main.tf` atual — apenas `idle-timeout-seconds`/metadados internos não fazem parte deste módulo (esse padrão de metadata é do módulo `workbench`, não do `vm`). Ou seja, passar `startup_script` ou `metadata` hoje não tem efeito prático até que o `main.tf` seja ajustado para consumi-los.
