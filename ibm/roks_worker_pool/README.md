# roks_worker_pool

Módulo que provisiona **worker pools adicionais** em um cluster Red Hat OpenShift on IBM Cloud (ROKS) já existente. É o módulo "filho" na dupla [`roks_cluster`](../roks_cluster/README.md) + `roks_worker_pool` — o cluster (com seu pool default) é criado pelo outro módulo, e o ID real dele é passado para cá via output. Mesmo papel que o `gcp/gke_nodepool` cumpre para o `gcp/gke`.

## Recursos criados

- `ibm_container_vpc_worker_pool.this` — um worker pool adicional no cluster. Nome do pool igual à chave do mapa (`worker_pool_name = <chave>`). Suporta múltiplas zonas (`zones` dinâmico), taints (`taints` dinâmico) e licenciamento via Cloud Pak (`entitlement`).

## Como usar

```hcl
module "roks_worker_pool" {
  source = "./ibm/roks_worker_pool"

  roks_worker_pool_settings = {
    gpu_workloads = {
      cluster_id        = module.roks_cluster.cluster_ids["hub_decision_broker"]
      vpc_id            = "r010-1a2b3c4d-5e6f-7890-abcd-ef1234567890"
      resource_group_id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"

      flavor       = "gx2.8x64.l4"
      worker_count = 1

      zones = [
        { name = "br-sao-1", subnet_id = "0717-...-000000000001" },
      ]

      labels = {
        workload = "gpu"
      }

      taints = [
        { key = "workload", value = "gpu", effect = "NoSchedule" },
      ]
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `roks_worker_pool_settings` | Mapa de configuração dos worker pools adicionais. Cada chave representa um worker pool lógico. | `map(object({...}))` | — | Sim |

Campos do objeto (`roks_worker_pool_settings["<chave>"]`):

| Campo | Descrição | Tipo | Default | Obrigatório |
|-------|-----------|------|---------|:-----------:|
| `cluster_id` | ID do cluster ROKS já existente (ex: `cluster_ids` do módulo `roks_cluster`) | `string` | — | Sim |
| `vpc_id` | Mesma VPC do cluster | `string` | — | Sim |
| `resource_group_id` | Resource group do worker pool | `string` | `null` | Não |
| `flavor` | Perfil de máquina dos workers deste pool (ex: `"bx2.8x32"`, `"gx2.8x64.l4"` para GPU) | `string` | — | Sim |
| `worker_count` | Workers por zona | `number` | `2` | Não |
| `zones` | Lista de zonas da VPC com seus respectivos `subnet_id` | `list(object({ name, subnet_id }))` | — | Sim |
| `labels` | Labels aplicadas aos nós deste pool | `map(string)` | `{}` | Não |
| `taints` | Taints aplicados aos nós deste pool (`key`, `value`, `effect`) | `list(object({ key, value, effect }))` | `[]` | Não |
| `entitlement` | `"cloud_pak"` se a licença do OpenShift vier de um Cloud Pak já possuído | `string` | `null` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `worker_pool_ids` | Mapa chave => ID do worker pool criado |

## Observações

- **Sem IAM próprio**: worker pools não têm política de IAM independente do cluster no IBM Cloud — o controle de acesso é feito inteiramente no nível do cluster, via `iam_bindings` do módulo `roks_cluster`.
- **Use taints para isolar workloads**: o padrão comum para nós especializados (GPU, alta memória) é combinar `taints` aqui com as tolerations correspondentes nos manifests do OpenShift/Kubernetes que forem rodar nesses nós — o módulo só aplica o taint, não gerencia tolerations (isso é responsabilidade dos workloads).
- **Mesma VPC do cluster**: `vpc_id` e as subnets em `zones` precisam pertencer à mesma VPC usada pelo cluster em `roks_cluster` — pools em VPCs diferentes não são suportados.
- Veja `example.tfvars` no diretório do módulo para um exemplo completo de `tfvars` (pool de GPU com taint dedicado).
