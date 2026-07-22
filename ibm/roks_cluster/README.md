# roks_cluster

Módulo que provisiona **clusters Red Hat OpenShift on IBM Cloud (ROKS)** em VPC. É o módulo "pai" na dupla `roks_cluster` + [`roks_worker_pool`](../roks_worker_pool/README.md), espelhando o mesmo padrão do par `gcp/gke` + `gcp/gke_nodepool`: o cluster é criado aqui, já com um pool de workers default, e pools adicionais (ex: nós com GPU, nós dedicados a uma workload) são criados pelo módulo `roks_worker_pool`, referenciando o cluster real via output.

O módulo **não cria VPC nem subnets** — eles precisam já existir (mesma filosofia do `gke`, que consome uma Shared VPC pré-existente em vez de criar rede).

## Recursos criados

- `ibm_container_vpc_cluster.this` — o cluster ROKS. Nome final composto como `roks-<sigla>-<workspace>`. `offering` fixado em `"openshift"` (não Kubernetes puro). Cria também o pool de workers **default** (definido implicitamente pelos campos `flavor`/`worker_count`/`zones` do próprio recurso). Suporta múltiplas zonas (`zones` dinâmico) para alta disponibilidade, master privado (`disable_public_service_endpoint`), CRN de uma instância COS para o registry interno (`cos_instance_crn`) e licenciamento via Cloud Pak (`entitlement`).
- `ibm_iam_access_group_policy.manager` / `.operator` / `.viewer` — bindings de IAM concedendo os papéis `Manager`, `Operator` e `Viewer` do serviço `containers-kubernetes` a access groups. **Importante**: o escopo real é o `resource_group_id` do cluster, não o cluster individualmente — veja Observações.

## Como usar

```hcl
module "roks_cluster" {
  source = "./ibm/roks_cluster"

  roks_cluster_settings = {
    hub_decision_broker = {
      sigla             = "sipml"
      resource_group_id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6" # dedicado a este cluster, ver Observacoes
      vpc_id            = "r010-1a2b3c4d-5e6f-7890-abcd-ef1234567890"

      flavor       = "bx2.4x16"
      kube_version = "4.15_openshift"
      worker_count = 2

      zones = [
        { name = "br-sao-1", subnet_id = "0717-...-000000000001" },
        { name = "br-sao-2", subnet_id = "0717-...-000000000002" },
        { name = "br-sao-3", subnet_id = "0717-...-000000000003" },
      ]

      cos_instance_crn = module.cos_instance.instance_crns["hub_decision_broker"]

      disable_public_service_endpoint = true

      tags   = ["camada:hub", "uso:decision-broker"]
      labels = { camada = "hub" }

      iam_bindings = {
        managers  = ["AccessGroupId-1111aaaa-2222-bbbb-3333-cccc4444dddd"]
        operators = ["AccessGroupId-5555eeee-6666-ffff-7777-gggg8888hhhh"]
        viewers   = []
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `roks_cluster_settings` | Mapa de configuração dos clusters ROKS. Cada chave representa um cluster lógico. | `map(object({...}))` | — | Sim |

Campos do objeto (`roks_cluster_settings["<chave>"]`):

| Campo | Descrição | Tipo | Default | Obrigatório |
|-------|-----------|------|---------|:-----------:|
| `sigla` | Sigla usada na composição do nome do cluster | `string` | — | Sim |
| `resource_group_id` | Resource group do cluster. Também define o escopo dos bindings de IAM deste cluster | `string` | — | Sim |
| `vpc_id` | ID da VPC já existente onde o cluster será criado | `string` | — | Sim |
| `flavor` | Perfil de máquina dos workers do pool default (ex: `"bx2.4x16"`) | `string` | — | Sim |
| `kube_version` | Versão do OpenShift (ex: `"4.15_openshift"`); `null` usa a versão default do offering | `string` | `null` | Não |
| `worker_count` | Workers por zona, no pool default | `number` | `2` | Não |
| `zones` | Lista de zonas da VPC com seus respectivos `subnet_id` — 3 zonas é o mínimo recomendado para HA em produção | `list(object({ name, subnet_id }))` | — | Sim |
| `cos_instance_crn` | CRN de uma instância COS existente, obrigatória para OpenShift (usada para o registry interno de imagens). Ver módulo `cos_instance` | `string` | — | Sim |
| `entitlement` | `"cloud_pak"` se a licença do OpenShift vier de um Cloud Pak já possuído | `string` | `null` | Não |
| `disable_public_service_endpoint` | Se `true`, o master do cluster só é acessível pela rede privada | `bool` | `true` | Não |
| `wait_till` | Estágio de criação em que o Terraform considera o cluster pronto (`MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady`, `Normal`) | `string` | `"IngressReady"` | Não |
| `tags` | Tags aplicadas ao cluster | `list(string)` | `[]` | Não |
| `labels` | Labels aplicadas aos workers do pool default | `map(string)` | `{}` | Não |
| `iam_bindings.managers` | IDs de access group com papel `Manager` no serviço `containers-kubernetes`, dentro do `resource_group_id` do cluster | `list(string)` | `[]` | Não |
| `iam_bindings.operators` | IDs de access group com papel `Operator` | `list(string)` | `[]` | Não |
| `iam_bindings.viewers` | IDs de access group com papel `Viewer` | `list(string)` | `[]` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `cluster_ids` | Mapa chave => ID do cluster ROKS. Usar como `cluster_id` no módulo `roks_worker_pool` |
| `cluster_crns` | Mapa chave => CRN do cluster ROKS |
| `ingress_hostnames` | Mapa chave => hostname de ingress atribuído ao cluster |
| `public_service_endpoint_urls` | Mapa chave => URL pública do master (API), quando `disable_public_service_endpoint = false` |
| `private_service_endpoint_urls` | Mapa chave => URL privada do master (API) |
| `cluster_states` | Mapa chave => estado atual do cluster |

## Observações

- **VPC/subnets pré-existentes**: assim como o `gke`, este módulo assume que a VPC e as subnets de cada zona já existem — ele só referencia (`vpc_id`, `zones[].subnet_id`), nunca cria rede.
- **IAM é escopado por resource group, não por cluster individual**: o provider IBM não expõe um atributo estável e documentado para restringir uma `ibm_iam_access_group_policy` a um único cluster (o equivalente ao `resource_type=bucket` usado no módulo `cos_bucket`). Por isso, os bindings deste módulo concedem acesso a **todos os clusters ROKS dentro do `resource_group_id` informado**. Na prática, isso significa: **dedique um resource group por cluster** se precisar de isolamento de acesso entre clusters — é o padrão mais comum em ambientes IBM Cloud justamente por essa limitação do IAM.
- **CMEK/COS obrigatório**: `cos_instance_crn` é exigido pela própria API do OpenShift (usado pelo registry interno de imagens) — use o output `instance_crns` do módulo `cos_instance` para encadear.
- **Cluster privado por padrão**: `disable_public_service_endpoint = true` é o default deste módulo — o master só é alcançável pela rede privada da VPC (ou por um jump host/bastion, como o `vmjumper`). Mude para `false` explicitamente se precisar de acesso público ao master.
- **Bindings são aditivos**: `ibm_iam_access_group_policy` não é autoritativo — adiciona a política ao access group sem remover outras já existentes.
- **Encadeamento com `roks_worker_pool`**: o output `cluster_ids` deve ser passado como `cluster_id` no módulo `roks_worker_pool` para adicionar pools de workers além do default (ex: nós com GPU, nós dedicados).
- Veja `example.tfvars` no diretório do módulo para um exemplo completo de `tfvars`.
