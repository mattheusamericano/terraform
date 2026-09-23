# colab_runtime

Módulo Terraform para provisionar templates de runtime do **Vertex AI Colab Enterprise** (`google_colab_runtime_template`), incluindo as permissões de rede necessárias para que o serviço do Vertex AI utilize uma subnet compartilhada de um projeto de infraestrutura (Shared VPC). O módulo também contém, comentado, o recurso de runtime propriamente dito (`google_colab_runtime`), que instancia um runtime a partir do template.

## Relação entre `colab_runtime.tf` e `colab_runtime_template.tf`

Os dois arquivos representam duas camadas do mesmo recurso do Vertex AI Colab Enterprise:

- **`colab_runtime_template.tf`** define o **template** (`google_colab_runtime_template`) — a especificação reutilizável de máquina, disco, rede e política de idle-shutdown que qualquer runtime criado a partir dele vai herdar. É o único recurso efetivamente ativo neste módulo hoje.
- **`colab_runtime.tf`** define o **runtime** (`google_colab_runtime`) em si, que referencia o template via `notebook_runtime_template_ref` e representa a instância de execução (o "notebook rodando") usada por um usuário. **Este recurso está inteiramente comentado no código atual** — ou seja, o módulo, como está, só cria o template, não o runtime ativo. Para ativá-lo seria necessário descomentar o bloco e revisar o mapeamento de `runtime_user`.

## Recursos criados

- `google_colab_runtime_template.runtime-template` — cria o template de runtime do Colab Enterprise (machine spec, disco persistente, rede e idle shutdown), um para cada chave de `var.colab_runtime_template_settings`.
- `google_compute_subnetwork_iam_member.vertex-service-agent-role-network` — concede `roles/compute.networkUser` na subnet compartilhada ao service agent do Vertex AI (`service-<project_number>@gcp-sa-aiplatform.iam.gserviceaccount.com`).
- `google_compute_subnetwork_iam_member.vertex-service-agent-network-viewer` — concede `roles/compute.networkViewer` na mesma subnet ao mesmo service agent do Vertex AI.
- `google_compute_subnetwork_iam_member.vertex-nb-service-role-network-user` — concede `roles/compute.networkUser` na subnet compartilhada ao service agent de notebooks (`service-<project_number>@gcp-sa-vertex-nb.iam.gserviceaccount.com`).
- `google_colab_runtime.runtime` *(comentado / inativo)* — criaria o runtime ativo a partir do template, com `desired_state = "ACTIVE"` e `auto_upgrade = true`.
- `google_project_service_identity.colab_runtime_template_aiplatform` — *(só com CMEK)* service agent do Vertex AI (`aiplatform.googleapis.com`), por projeto.
- `google_kms_crypto_key_iam_member.colab_runtime_template` — *(só com CMEK)* concede `roles/cloudkms.cryptoKeyEncrypterDecrypter` na chave ao service agent, um binding por combinação projeto+chave.

## Data sources utilizados

- `data.google_project.project` — resolve o número do projeto atual, usado para montar os e-mails dos service agents do Vertex AI nos bindings de IAM.

## Como usar

```hcl
module "colab_runtime" {
  source = "./gcp/colab_runtime"

  colab_runtime_template_settings = {
    "runtime-ds" = {
      project_id             = "meu-projeto-gcp"
      region                 = "us-central1"
      sigla                  = "cre"
      machine_type           = "n1-standard-4"
      accelerator_type       = "NVIDIA_TESLA_T4"
      accelerator_count      = "1"
      disk_type              = "PD_SSD"
      disk_size_gb           = 100
      network_project_id     = "projeto-infra-compartilhada"
      name_vpc_shared        = "vpc-shared"
      name_subnet_vpc_shared = "subnet-us-central1"
      labels = {
        time = "data-science"
      }
      runtime_user = "usuario@empresa.com"
      runtime_name = "runtime-ds"
    }

    "runtime-ds-cmek" = {
      project_id             = "meu-projeto-gcp"
      region                 = "us-central1"
      sigla                  = "cre"
      machine_type           = "n1-standard-4"
      disk_type              = "PD_SSD"
      disk_size_gb           = 100
      network_project_id     = "projeto-infra-compartilhada"
      name_vpc_shared        = "vpc-shared"
      name_subnet_vpc_shared = "subnet-us-central1"
      labels = {
        time = "data-science"
      }

      kms_project_id = "prj-hsm-services-prd"
      kms_key_ring   = "infrahsmPRDring"
      kms_crypto_key = "infraPRDSYMAES256hsm001"
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `colab_runtime_template_settings` | Mapa de templates de runtime a serem criados. `project_id` é o projeto onde o template é provisionado, `region` a localização do template, `sigla` um sufixo de nomenclatura, `machine_type` o tipo de máquina, `accelerator_type`/`accelerator_count` a GPU e quantidade (opcionais), `disk_type`/`disk_size_gb` o disco persistente de dados, `network_project_id`/`name_vpc_shared`/`name_subnet_vpc_shared` identificam a VPC e subnet compartilhadas usadas pelo template (sem acesso à internet), `labels` rótulos do recurso, `runtime_user`/`runtime_name` (opcionais) usados apenas pelo recurso de runtime hoje comentado, e `kms_project_id`/`kms_key_ring`/`kms_crypto_key` (opcionais, sempre juntos) para criptografar o template com CMEK. | `map(object({ project_id = string, region = string, sigla = string, machine_type = string, accelerator_type = optional(string), accelerator_count = optional(string), disk_type = string, disk_size_gb = number, network_project_id = string, name_vpc_shared = string, name_subnet_vpc_shared = string, labels = map(any), runtime_user = optional(string), runtime_name = optional(string), kms_project_id = optional(string), kms_key_ring = optional(string), kms_crypto_key = optional(string) }))` | — | Sim |

## Outputs

Este módulo não define outputs.

## Observações

- **CMEK é totalmente opcional e não altera nada quando não é usado**: sem `kms_project_id`/`kms_key_ring`/`kms_crypto_key` em nenhum template, o módulo não cria nenhum recurso de IAM/service identity e os templates seguem exatamente como antes (sem diff no `plan`). O módulo monta `kms_key_name = "projects/<kms_project_id>/locations/<region>/keyRings/<kms_key_ring>/cryptoKeys/<kms_crypto_key>"` (a location da chave reaproveita a `region` do template, não é um campo separado) e aplica no bloco `encryption_spec` — os 3 campos são obrigatórios juntos, validado em `variables.tf`.
- **Permissão na chave (criada pelo módulo quando há CMEK)**: para cada projeto com template CMEK, o módulo cria o service agent do Vertex AI (`google_project_service_identity`, `service-<PROJECT_NUMBER>@gcp-sa-aiplatform.iam.gserviceaccount.com`) e concede a ele `roles/cloudkms.cryptoKeyEncrypterDecrypter` na chave (`google_kms_crypto_key_iam_member`, em `iam.tf`). O template tem `depends_on` nesse binding. Templates do mesmo projeto que usam a mesma chave compartilham um único binding. `google_project_service_identity` exige o provider `google-beta` na stack (mesmo requisito do módulo `workbench`), e quem roda o `apply` precisa poder conceder IAM na chave KMS — se o primeiro `apply` falhar por acesso à chave logo após criar o binding, aguarde a propagação e rode de novo.

- Todo o módulo é orientado por `for_each` sobre `colab_runtime_template_settings`; cada chave do mapa gera um template independente e seus respectivos bindings de IAM na subnet.
- O nome do template segue o padrão `${chave}-${sigla}-${terraform.workspace}`.
- `network_spec.enable_internet_access` é fixado como `false` no template — os runtimes criados a partir dele não têm acesso direto à internet, apenas à rede compartilhada informada.
- `idle_shutdown_config.idle_timeout` é fixo em `3600s` (1 hora) para todos os templates.
- As três permissões de IAM na subnet (`google_compute_subnetwork_iam_member.*`) são concedidas no projeto de rede (`network_project_id`), não no projeto do template — é essencial que quem aplicar este módulo tenha permissão de admin de IAM na subnet do projeto de infraestrutura compartilhada.
- O recurso `google_colab_runtime.runtime` e o binding `google_project_iam_member.aiplatform_user` (que concederia `roles/aiplatform.colabEnterpriseUser` ao `runtime_user`) estão comentados no código-fonte. Para que o runtime seja de fato criado e utilizável por um usuário, esses blocos precisam ser revisados e descomentados.
