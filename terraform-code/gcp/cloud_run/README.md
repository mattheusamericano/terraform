# cloud_run

Módulo que provisiona serviços **Cloud Run v2** (fully managed), cada um com sua própria Service Account dedicada, bindings de IAM mínimos para operar (Artifact Registry, Logging, Monitoring) e, opcionalmente, conectividade privada via VPC Connector para uma Shared VPC.

## Recursos criados

- `google_cloud_run_v2_service.service` — o serviço Cloud Run em si. Ingress fixado em `INGRESS_TRAFFIC_INTERNAL_ONLY` (não aceita tráfego público direto da internet). Container único por serviço, com limites de CPU/memória e `max_instance_count` configuráveis. Suporta `vpc_access` opcional (egress `ALL_TRAFFIC`) quando um VPC connector é informado.
- `google_service_account.cloudrun_sa` — uma Service Account dedicada por serviço, usada como identidade de runtime do container.
- `google_project_service_identity.run_identity` — Service Identity (Service Agent) do Cloud Run, criada uma vez por projeto (via `google-beta`), necessária para o Cloud Run operar corretamente no projeto.
- `google_project_iam_member.artifact_registry_reader` — concede `roles/artifactregistry.reader` à SA do serviço (necessário para puxar a imagem do container).
- `google_project_iam_member.log_writer` — concede `roles/logging.logWriter` à SA.
- `google_project_iam_member.monitoring_writer` — concede `roles/monitoring.metricWriter` à SA.
- `google_compute_subnetwork_iam_member.cloudrun_network_user` — concede `roles/compute.networkUser` na subnet da Shared VPC, apenas para os serviços que definem `vpc_connector`.
- `data.google_project.project` — usado internamente para calcular o conjunto de projetos únicos (base para a Service Identity).

## Como usar

```hcl
module "cloud_run" {
  source = "./gcp/cloud_run"

  cloud_run_settings = {
    api_pagamentos = {
      project_id    = "prj-sipml-gateway-prd"
      region        = "southamerica-east1"
      sigla         = "sipml"
      image         = "southamerica-east1-docker.pkg.dev/prj-sipml-gateway-prd/apps/api-pagamentos:1.0.0"
      cpu           = "1"
      memory        = "512Mi"
      max_scale     = 5
      sa_account_id = "sa-cloudrun-api-pagamentos"
      labels = {
        camada = "api"
      }

      # Opcional: acesso à Shared VPC via connector
      vpc_connector           = "projects/prj-network-shared/locations/southamerica-east1/connectors/vpc-conn-prd"
      network_project_id      = "prj-network-shared"
      name_subnet_vpc_shared  = "subnet-apps-prd"

      # Opcional: CMEK (atualmente comentado no recurso, ver Observações)
      kms_project_id = null
      key_ring       = null
      key_crypto     = null
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `cloud_run_settings` | Mapa de configuração dos serviços Cloud Run. Cada chave é um serviço lógico. | `map(object({...}))` | — | Sim |

Campos do objeto (`cloud_run_settings["<chave>"]`):

| Campo | Descrição | Tipo | Default | Obrigatório |
|-------|-----------|------|---------|:-----------:|
| `project_id` | Projeto onde o serviço Cloud Run será criado | `string` | — | Sim |
| `region` | Região do serviço | `string` | — | Sim |
| `sigla` | Sigla usada na composição do nome do serviço | `string` | — | Sim |
| `image` | Imagem de container (Artifact Registry) a ser servida | `string` | — | Sim |
| `cpu` | Limite de CPU do container (ex: `"1"`) | `string` | — | Sim |
| `memory` | Limite de memória do container (ex: `"512Mi"`) | `string` | — | Sim |
| `max_scale` | Número máximo de instâncias (`max_instance_count`) | `number` | — | Sim |
| `sa_account_id` | `account_id` da Service Account dedicada do serviço | `string` | — | Sim |
| `labels` | Labels aplicadas ao serviço | `map(any)` | — | Sim |
| `vpc_connector` | ID do VPC Access Connector, para habilitar `vpc_access` | `string` | `null` | Não |
| `invoker` | Declarada mas não utilizada no `main.tf`/`iam.tf` atual (ver Observações) | `string` | `null` | Não |
| `network_project_id` | Projeto da Shared VPC, usado no binding `compute.networkUser` da subnet | `string` | `null` | Não |
| `name_subnet_vpc_shared` | Nome da subnet da Shared VPC, usado no mesmo binding | `string` | `null` | Não |
| `kms_project_id` | Projeto da chave KMS para CMEK | `string` | `null` | Não |
| `key_ring` | Key ring da chave KMS para CMEK | `string` | `null` | Não |
| `key_crypto` | Nome da chave KMS para CMEK | `string` | `null` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `cloud_run_urls` | Mapa chave => URL (`uri`) de cada serviço Cloud Run criado |

## Observações

- **Ingress sempre interno**: `ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"` está hardcoded — o serviço nunca fica acessível diretamente da internet pública, mesmo que o Cloud Run em si tenha essa opção. Exposição externa exige um Load Balancer/API Gateway na frente.
- **CMEK desligado**: a linha `encryption_key` em `main.tf` está comentada — mesmo preenchendo `kms_project_id`/`key_ring`/`key_crypto`, o serviço **não** é criptografado com CMEK hoje. As variáveis existem mas não têm efeito.
- **`invoker` não usado**: a variável `invoker` é declarada em `variables.tf` mas não há nenhum `google_cloud_run_v2_service_iam_member`/binding de invocação no módulo — quem pode chamar o serviço não é controlado por aqui.
- **VPC connector é opcional por serviço**: o `dynamic "vpc_access"` e o binding `compute.networkUser` só são criados quando `vpc_connector != null`. Se usar `vpc_connector`, é obrigatório também preencher `network_project_id` e `name_subnet_vpc_shared`, senão o binding de rede fica com valores nulos.
- **Ordem de criação**: o serviço depende explicitamente da SA e da Service Identity do projeto (`depends_on`), garantindo que a identidade do Cloud Run já exista no projeto antes do deploy do serviço.
