# gke_nodepool

Módulo Terraform para provisionar **node pools adicionais** (de aplicação) em um cluster GKE já existente. É complementar ao módulo `gke`, que cria o cluster e seu node pool de sistema — este módulo é usado para adicionar quantos node pools de workload forem necessários, tipicamente consumindo os outputs do módulo `gke` (nome do cluster e e-mail da Service Account dos nodes).

## Recursos criados

- `google_container_node_pool.nodepool` — cria um node pool por entrada do mapa `gke_nodepool_settings`, associado a um cluster existente (`cluster_name`), com autoscaling, estratégia de upgrade em `SURGE`, auto-repair/auto-upgrade habilitados, disco configurável, Shielded VM, Workload Identity (`GKE_METADATA`) e uso de VMs spot fora do workspace `prd`.

## Como usar

```hcl
module "gke_nodepool" {
  source = "./gcp/gke_nodepool"

  gke_nodepool_settings = {
    apps = {
      project_id   = "meu-projeto-gke"
      region       = "us-central1"
      zone         = "us-central1-a"
      sigla        = "plat"
      cluster_name = module.gke.cluster_names["plataforma"]
      gke_sa_email = module.gke.gke_sa_emails["plataforma"]

      machine_type      = "e2-standard-8"
      max_pods_per_node = 110
      disk_type         = "pd-ssd"
      disk_size_gb      = 100

      min_node_count = 1
      max_node_count = 5

      taint_value = "apps"

      labels = {
        ambiente = "prd"
        squad    = "plataforma"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `gke_nodepool_settings` | Mapa de node pools a serem criados. A chave do mapa é usada como nome do node pool. | `map(object({ project_id, region, zone, sigla, cluster_name, gke_sa_email, machine_type=optional(string,"e2-standard-4"), max_pods_per_node=optional(number,200), disk_type=optional(string,"pd-ssd"), disk_size_gb=optional(number,100), min_node_count=optional(number,1), max_node_count=optional(number,2), taint_value=string, labels=optional(map(string),{}) }))` | — | sim |

### Estrutura de `gke_nodepool_settings`

Cada entrada do mapa representa um node pool e deve conter:

- `project_id` — projeto onde o cluster (e o node pool) existem.
- `region` — região do node pool; em `prd` a `location` é a região, nos demais workspaces é `região-zona` (usa também `zone`).
- `zone` — zona usada quando o workspace não é `prd`.
- `sigla` — sigla do time/domínio (documentacional, não usada diretamente na composição do nome do pool, que é a própria chave do mapa).
- `cluster_name` — nome do cluster GKE de destino; normalmente vem do output `cluster_names` do módulo `gke`.
- `gke_sa_email` — e-mail da Service Account que os nodes usarão; normalmente vem do output `gke_sa_emails` do módulo `gke`.
- `machine_type` (opcional, default `e2-standard-4`) — tipo de máquina dos nodes.
- `max_pods_per_node` (opcional, default `200`) — máximo de pods por node.
- `disk_type` (opcional, default `pd-ssd`) — tipo de disco.
- `disk_size_gb` (opcional, default `100`) — tamanho do disco em GB.
- `min_node_count` / `max_node_count` (opcionais, default `1`/`2`) — limites de autoscaling.
- `taint_value` — valor declarado na configuração, mas atualmente **não aplicado** (o bloco `taint` do node pool está comentado no código — ver Observações).
- `labels` (opcional, default `{}`) — labels mescladas com `environment`, `role=user` e `nodepool=<chave>` nos labels dos nodes.

## Outputs

Este módulo não declara outputs (`outputs.tf` está vazio).

## Observações

- O nome do node pool é a própria chave usada em `gke_nodepool_settings` (`name = "${each.key}"`) — escolha chaves que façam sentido como nome de node pool no GKE (minúsculas, sem espaços).
- O bloco `taint` está comentado no `main.tf`; portanto, apesar de `taint_value` ser uma variável obrigatória, nenhum taint é aplicado aos nodes atualmente. Isso significa que qualquer pod pode ser agendado nesses node pools, ao contrário do node pool `system` do módulo `gke` (que possui taint `CriticalAddonsOnly`).
- Em ambientes fora de `prd`, os nodes usam VMs spot (`spot = terraform.workspace == "prd" ? false : true`), o que pode causar preempções — não recomendado para workloads críticos fora de produção sem tolerância a interrupções.
- O módulo depende de um cluster e de uma Service Account já existentes — não cria nem gerencia o cluster; use em conjunto com o módulo `gke`, passando `cluster_name` e `gke_sa_email` a partir dos outputs desse módulo.
- `lifecycle.ignore_changes` em `node_config[0].resource_labels` evita drift/recriação quando o GKE ajusta labels internamente nos nodes.
