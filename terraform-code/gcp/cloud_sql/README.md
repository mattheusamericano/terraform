# cloud_sql

Módulo Terraform para provisionar instâncias **Cloud SQL** privadas (sem IP público), criptografadas via Cloud KMS (CMEK), com backup automático, janela de manutenção, política de senha e uma Service Account dedicada para acesso via Cloud SQL Auth Proxy. A senha do usuário `root`/admin é gerada automaticamente e armazenada no Secret Manager. Como os demais módulos deste repositório, é orientado a `for_each` sobre um mapa de configurações (`cloud_sql_instance_settings`).

## Recursos criados

- `google_sql_database_instance.main` — a instância Cloud SQL, com `name` derivado da chave do mapa, `root_password` gerado automaticamente, criptografia via `encryption_key_name` (KMS), `deletion_protection = false`, IP privado apenas (`ipv4_enabled = false`, `private_network` apontando para a VPC compartilhada), `ssl_mode = "ENCRYPTED_ONLY"`, backup diário às 02:00 com 30 backups retidos, janela de manutenção fixa aos domingos às 06:00 UTC, política de senha (mínimo 12 caracteres) e `query_insights` habilitado apenas no workspace `prd`. A disponibilidade (`REGIONAL`/`ZONAL`) e o autoresize de disco também variam conforme `terraform.workspace == "prd"`.
- `google_service_account.sql_proxy_sa` — Service Account dedicada por instância, destinada ao Cloud SQL Auth Proxy.
- `google_project_iam_member.sql_client` — concede `roles/cloudsql.client` no projeto à SA do proxy de cada instância.
- `google_project_iam_member.group_users_client` — concede `roles/cloudsql.client` no projeto ao grupo definido em `group_users`.
- `google_kms_crypto_key_iam_member.sql_kms` — concede `roles/cloudkms.cryptoKeyEncrypterDecrypter` na chave KMS à SA do proxy de cada instância.
- `random_password.admin_password` — senha aleatória de 20 caracteres (com regras de complexidade) gerada uma única vez e reutilizada como senha de administrador em **todas** as instâncias do mapa.
- `google_secret_manager_secret.sql_admin_password` — um secret por instância no Secret Manager, com réplica gerenciada pelo usuário na região da instância.
- `google_secret_manager_secret_version.sql_admin_password_version` — versão do secret contendo a senha de admin gerada.
- `data.google_compute_network.vpc` — resolve a VPC compartilhada (`name_vpc_shared`) no projeto de rede (`network_project_id`) de cada instância.
- `data.google_kms_key_ring.keyring` / `data.google_kms_crypto_key.keycrypto` — resolvem o keyring/chave KMS usados na criptografia de cada instância.

## Como usar

```hcl
module "cloud_sql" {
  source = "./gcp/cloud_sql"

  cloud_sql_instance_settings = {
    app-principal = {
      project_id            = "prj-dados-dev"
      region                = "southamerica-east1"
      sigla                 = "eng"
      tier                  = "db-custom-2-8192"
      database_version      = "POSTGRES_15"
      disk_type             = "PD_SSD"
      disk_size             = 50
      disk_autoresize_limit = 200

      network_project_id = "prj-network-shared-dev"
      name_vpc_shared     = "vpc-shared-dev"

      key_ring       = "kr-cloudsql"
      key_crypto     = "key-cloudsql"
      kms_project_id = "prj-kms-dev"

      labels = {
        squad = "engenharia-dados"
      }

      group_users = "gcp-cloudsql-app-users@empresa.com"
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `cloud_sql_instance_settings` | Mapa de configurações das instâncias Cloud SQL a criar (sem `description` no código) | `map(object({...}))` | — | sim |

### Estrutura de cada item de `cloud_sql_instance_settings`

| Atributo | Tipo | Default | Descrição |
|----------|------|---------|-----------|
| `project_id` | `string` | — | Projeto onde a instância é criada |
| `region` | `string` | — | Região da instância |
| `sigla` | `string` | — | Sigla usada na composição do nome da instância e da SA do proxy |
| `tier` | `string` | — | Tipo de máquina da instância (ex.: `db-custom-2-8192`) |
| `database_version` | `string` | — | Versão do banco (ex.: `POSTGRES_15`, `MYSQL_8_0`) |
| `disk_type` | `string` | — | Tipo de disco (ex.: `PD_SSD`, `PD_HDD`) |
| `disk_size` | `number` | — | Tamanho inicial do disco em GB |
| `disk_autoresize_limit` | `number` | opcional (sem default) | Limite máximo de crescimento automático do disco |
| `network_project_id` | `string` | — | Projeto host da Shared VPC usada pela instância |
| `name_vpc_shared` | `string` | — | Nome da VPC compartilhada |
| `key_ring` | `string` | — | Nome do keyring KMS usado na criptografia da instância |
| `key_crypto` | `string` | — | Nome da chave KMS usada na criptografia da instância |
| `kms_project_id` | `string` | — | Projeto onde vive a chave KMS |
| `labels` | `map(any)` | — | Labels (`user_labels`) aplicadas à instância |
| `group_users` | `string` | — | Grupo do Google que recebe `roles/cloudsql.client` no projeto |

## Outputs

Este módulo não declara nenhum output (não há `outputs.tf`/`output.tf` no diretório). Para consumir a instância, senha ou SA do proxy em outros módulos, seria necessário adicionar outputs (ex.: `connection_name`, e-mail da SA do proxy, ID do secret da senha).

## Observações

- **A senha de administrador é única e compartilhada entre todas as instâncias do mapa**: `random_password.admin_password` é gerado uma única vez (não está dentro de um `for_each`) e o mesmo valor (`local.admin_password`) é usado como `root_password` de cada instância criada. Cada instância recebe, porém, seu próprio secret no Secret Manager (`sql_admin_password[each.key]`) contendo essa mesma senha.
- `ignore_changes = [root_password]` no `lifecycle` da instância significa que, após o primeiro apply, alterações na senha (inclusive rotações manuais) não são reaplicadas automaticamente pelo Terraform. O mesmo vale para `secret_data` no secret (`ignore_changes = [secret_data]`) — se a senha for rotacionada fora do Terraform, o state não tentará reverter.
- **A criação da conexão privada (Private Services Access / VPC Peering) está comentada em `network.tf`** (`google_compute_global_address.private_ip_range` e `google_service_networking_connection.private_vpc_connection`). Isso significa que este módulo **não provisiona** o peering necessário para IP privado — ele assume que a VPC compartilhada (`data.google_compute_network.vpc`) já possui essa conexão configurada previamente.
- O binding `google_kms_crypto_key_iam_member.sql_kms` concede a permissão de KMS à **Service Account do proxy (`sql_proxy_sa`)**, não à Service Agent nativa do Cloud SQL (`service-<project-number>@gcp-sa-cloud-sql.iam.gserviceaccount.com`). O comentário no código ("Permissão de criptografia para Service Agent Notebook") não corresponde ao principal usado — vale confirmar se a Service Agent do Cloud SQL também precisa desse binding para a criptografia CMEK funcionar corretamente.
- A disponibilidade (`REGIONAL` vs `ZONAL`), o autoresize de disco e o `query_insights_enabled` dependem do valor de `terraform.workspace`: só ficam com a configuração "produção" quando o workspace é literalmente `"prd"`.
- O bloco de `authorized_networks` dentro de `ip_configuration` está comentado no código — atualmente não é possível autorizar redes externas via este módulo.
- `deletion_protection = false`: a instância pode ser destruída diretamente pelo Terraform, sem proteção adicional do provider contra exclusão acidental.
