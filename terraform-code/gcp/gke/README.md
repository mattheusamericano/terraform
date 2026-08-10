# gke

Módulo Terraform responsável por provisionar um **cluster GKE privado** completo, incluindo rede (integração com Shared VPC existente), Service Account dedicada com permissões mínimas, node pool de sistema, DNS interno gerenciado por External DNS, e Cloud Service Mesh (Istio gerenciado pelo Google via Fleet/Hub). É o módulo "núcleo" da plataforma GKE — node pools de aplicação adicionais são criados separadamente pelo módulo `gke_nodepool`, que consome os outputs deste módulo.

## Recursos criados

### Cluster e node pool de sistema
- `google_container_cluster.cluster` — cria o cluster GKE privado (sem node pool default — `remove_default_node_pool = true`), com Workload Identity habilitado, Shielded Nodes, endpoint privado, `master_authorized_networks_config` fixo para a faixa interna `10.250.0.0/16`, canal de release `STABLE`, janela de manutenção fixa (fins de semana), addons de HTTP load balancing, HPA, CSI de Persistent Disk e GCS FUSE, e `security_posture_config` em modo básico.
- `google_container_node_pool.nodepool_system` — cria o node pool `system`, dedicado a workloads do próprio Kubernetes (com taint `CriticalAddonsOnly=true:NO_SCHEDULE`), com autoscaling, auto-repair/auto-upgrade, disco SSD, Shielded VM e `workload_metadata_config` em modo `GKE_METADATA`. Em ambientes fora de `prd`, os nodes usam VMs spot.

### Service Account e IAM do cluster
- `google_service_account.gke_sa` — Service Account dedicada usada pelos nodes do cluster (system e demais node pools).
- `google_project_iam_member.gke_sa_roles` — concede ao `gke_sa` o conjunto mínimo de roles necessárias para operação dos nodes (`logging.logWriter`, `monitoring.metricWriter`, `monitoring.viewer`, `artifactregistry.reader`, `storage.objectViewer`), via combinação (`flatten`) de cluster x role.
- `google_project_iam_member.gke_sa_osconfig` — concede `roles/osconfig.guestPolicyViewer` ao `gke_sa`.

### IAM do Service Mesh / Fleet
- `google_project_iam_member.fleet_sa_gkehub_admin` — concede `roles/gkehub.admin` no projeto do cluster (para um SA fixo `service-373570785065@gcp-sa-gkenode.iam.gserviceaccount.com`, hardcoded no código — não é derivado do `local.fleet_sa` do próprio projeto).
- `google_project_iam_member.fleet_sa_serviceusage_admin` — concede `roles/serviceusage.serviceUsageAdmin` ao SA do Fleet Hub (`service-<project_number>@gcp-sa-servicemesh.iam.gserviceaccount.com`) no projeto do cluster.
- `google_project_iam_member.fleet_privateca_admin` — concede `roles/privateca.admin` ao SA do Fleet Hub, no projeto do cluster.
- `google_project_iam_member.mesh_sa_service_agent` — concede `roles/meshconfig.admin` ao SA do Fleet Hub, no projeto do cluster.
- `google_project_iam_member.anthosmesh_sa_service_agent` — concede `roles/anthosservicemesh.serviceAgent` ao SA do Fleet Hub, mas no **projeto de rede** (`network_project_id`), pois o mesh precisa operar sobre a Shared VPC.

### Rede (integração com Shared VPC)
- `google_compute_subnetwork_iam_member.gke_subnet_user` — concede `roles/compute.networkUser` ao service agent do GKE (`service-<project_number>@container-engine-robot.iam.gserviceaccount.com`) na subnet do host project.
- `google_project_iam_member.gke_host_service_agent` — concede `roles/container.hostServiceAgentUser` ao mesmo service agent, no projeto de rede.
- `google_project_iam_member.gke_network_user` — concede `roles/compute.networkUser` ao mesmo service agent, no projeto de rede (a nível de projeto, complementar ao binding a nível de subnet).
- `google_project_iam_member.fleet_sa_network_admin` — concede `roles/compute.networkAdmin` ao SA do Fleet Hub no projeto de rede.

### DNS interno (External DNS)
- `google_dns_managed_zone.interna` — cria uma zona DNS privada (`dns-internal-gke-<sigla>-<workspace>`) associada à VPC do cluster, para uso pelo controlador External DNS rodando dentro do cluster.
- `google_service_account.external_dns_service` — Service Account dedicada ao External DNS.
- `google_project_iam_member.external_dns_sa` — concede `roles/dns.admin` a essa SA no projeto do cluster.
- `google_service_account_iam_member.external_dns_wi` — vincula a SA via Workload Identity ao KSA `external-dns` no namespace `external-dns` (`<project_id>.svc.id.goog[external-dns/external-dns]`).

### Cloud Service Mesh (Fleet/Hub)
- `google_gke_hub_membership.membership` — registra o cluster como membership na Fleet do projeto.
- `google_gke_hub_feature.servicemesh` — habilita o feature `servicemesh` na Fleet (escopo `global`).
- `google_gke_hub_feature_membership.servicemesh_config` — associa o membership ao feature de service mesh com `management = "MANAGEMENT_AUTOMATIC"` (o Google gerencia automaticamente o ciclo de vida do Istio).

### Data sources utilizados
- `google_project.project` — resolve o número do projeto (usado para montar e-mails de service agents).
- `google_compute_network.vpc` — resolve a VPC compartilhada existente pelo nome.
- `google_compute_subnetwork.subnet` — resolve a subnet existente pelo nome/região no projeto de rede.
- `google_kms_key_ring.keyring` / `google_kms_crypto_key.gke_key` — resolvem keyring/chave KMS quando `kms_keyring`/`kms_crypto` são informados (ver Observações — atualmente não conectados a nenhum recurso do cluster).

## Como usar

```hcl
module "gke" {
  source = "./gcp/gke"

  gke_cluster_settings = {
    plataforma = {
      project_id = "meu-projeto-gke"
      region     = "us-central1"
      zone       = "us-central1-a"
      sigla      = "plat"

      network_project_id     = "meu-projeto-host-vpc"
      name_vpc_shared        = "vpc-shared-corp"
      subnet_name            = "sub-gke-plataforma"
      master_ipv4_cidr_block = "172.16.0.0/28"
      pods_range_name        = "gke-pods"
      services_range_name    = "gke-services"
      pods_cidr              = "192.168.0.0/16"
      services_cidr          = "10.245.0.0/22"

      system_min_node_count = 1
      system_max_node_count = 3
      system_machine_type   = "e2-standard-4"
      max_pods_per_node     = 110

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
| `gke_cluster_settings` | Mapa de clusters GKE a serem criados. | `map(object({ project_id, region, zone, sigla, network_project_id, name_vpc_shared, subnet_name, master_ipv4_cidr_block, pods_range_name, services_range_name, pods_cidr, services_cidr, system_min_node_count, system_max_node_count, system_machine_type, max_pods_per_node, master_authorized_networks, kms_project_id, kms_keyring, kms_crypto, labels }))` | — | sim |

### Estrutura de `gke_cluster_settings`

Cada entrada do mapa representa um cluster e deve conter:

- `project_id` — projeto onde o cluster será criado.
- `region` — região do cluster; em `prd` a `location` do cluster é a região (cluster regional); nos demais workspaces é `região-zona` (cluster zonal), usando também `zone`.
- `zone` (opcional) — zona usada quando o workspace não é `prd`.
- `sigla` — sigla usada na composição de nomes (cluster, SA, DNS).
- `network_project_id` — projeto host da Shared VPC.
- `name_vpc_shared` — nome da VPC compartilhada já existente.
- `subnet_name` — nome da subnet já existente no projeto de rede.
- `master_ipv4_cidr_block` — CIDR do control plane (**declarado mas atualmente não referenciado** no `private_cluster_config` do `main.tf` — ver Observações).
- `pods_range_name` / `services_range_name` — nomes dos secondary ranges já existentes na subnet, usados em `ip_allocation_policy`.
- `pods_cidr` / `services_cidr` — CIDRs correspondentes (documentacionais; a criação dos secondary ranges está comentada no `network.tf` — ver Observações).
- `system_min_node_count` / `system_max_node_count` — limites de autoscaling do node pool `system`.
- `system_machine_type` — tipo de máquina dos nodes do node pool `system`.
- `max_pods_per_node` (opcional, default `200`) — máximo de pods por node, aplicado ao node pool `system`.
- `master_authorized_networks` (opcional, default `[]`, lista de `{ name, cidr }`) — **declarada mas não usada** no `main.tf` atual (o CIDR autorizado está fixo em `10.250.0.0/16`).
- `kms_project_id` / `kms_keyring` / `kms_crypto` (opcionais, default `null`) — resolvidos via data source, mas **não conectados** a nenhum bloco de criptografia do cluster no código atual.
- `labels` — labels aplicadas ao cluster e propagadas (mescladas) aos labels dos nodes do node pool `system`.

## Outputs

| Nome | Descrição |
|------|-----------|
| `cluster_names` | Nomes dos clusters criados, indexados pela chave do mapa. |
| `cluster_endpoints` | Endpoints (IP do control plane) dos clusters. Marcado como `sensitive`. |
| `cluster_ids` | IDs dos clusters criados. |
| `gke_sa_emails` | E-mails das Service Accounts dos nodes — deve ser usado como input (`gke_sa_email`) do módulo `gke_nodepool`. |
| `cluster_ca_certificates` | Certificados de CA (`master_auth[0].cluster_ca_certificate`) dos clusters. Marcado como `sensitive`. |

## Observações

**Arquitetura geral:** o módulo assume uma topologia de Shared VPC — a VPC e a subnet (com secondary ranges para pods e services) já devem existir no `network_project_id` antes da execução; o módulo apenas resolve essas informações via data source e concede as permissões de IAM necessárias (`compute.networkUser`, `container.hostServiceAgentUser`) para o service agent do GKE operar sobre elas. O bloco que criaria os secondary ranges (`google_compute_subnetwork.gke_ranges`) está integralmente comentado em `network.tf`, reforçando que essa etapa é pré-requisito externo ao módulo, não responsabilidade dele.

**Cluster privado:** o cluster é sempre privado (`enable_private_nodes = true`, `enable_private_endpoint = true`), sem node pool default (`remove_default_node_pool = true`) — todo o compute vem do node pool `system` (criado por este módulo) e de node pools adicionais criados pelo módulo `gke_nodepool`, que depende do output `gke_sa_emails` e do nome do cluster.

**DNS:** o módulo cria uma zona DNS privada própria (`dns-internal-gke-<sigla>-<workspace>`, domínio `<sigla>.caixa.gov.br.`) associada à VPC do cluster, além de uma Service Account e binding de Workload Identity para o controlador External DNS (esperado rodando no namespace `external-dns` com KSA `external-dns` dentro do cluster). O módulo não instala o controlador em si (isso é feito via manifests/Helm fora do Terraform) — apenas prepara a infraestrutura de IAM/DNS que ele consome.

**Service Mesh:** o cluster é registrado como membership na Fleet (`google_gke_hub_membership`) e o feature `servicemesh` é habilitado com `management = "MANAGEMENT_AUTOMATIC"`, ou seja, o próprio Google gerencia o ciclo de vida do Istio gerenciado (sem necessidade de operar control plane do mesh manualmente). Para isso funcionar, o módulo concede diversas permissões ao service agent do Service Mesh (`service-<project_number>@gcp-sa-servicemesh.iam.gserviceaccount.com`, chamado de `local.fleet_sa` no `iam.tf`) tanto no projeto do cluster quanto no projeto de rede (`anthosservicemesh.serviceAgent`, necessário pois o mesh atua sobre a Shared VPC).

**Node pool de sistema:** roda com taint `CriticalAddonsOnly=true:NO_SCHEDULE`, isolando-o para componentes do próprio Kubernetes/GKE — cargas de aplicação devem ser agendadas nos node pools criados pelo módulo `gke_nodepool` (que não aplicam esse taint por padrão). Em ambientes não-`prd`, os nodes do pool `system` usam VMs spot para redução de custo; em `prd`, usam VMs on-demand.

**Dependências explícitas:** a criação do cluster (`google_container_cluster.cluster`) depende explicitamente (`depends_on`) das roles do `gke_sa` (`google_project_iam_member.gke_sa_roles`), garantindo que a SA já tenha as permissões mínimas antes do cluster (e seus node pools) subir.

**Itens declarados mas não conectados no código atual** (podem ser preparação para uso futuro):
- `master_ipv4_cidr_block` e `master_authorized_networks` (variáveis) não são referenciados no `private_cluster_config`/`master_authorized_networks_config` do `main.tf`, que usa o CIDR fixo `10.250.0.0/16`.
- `kms_project_id`, `kms_keyring`, `kms_crypto` são resolvidos via data source (`data.tf`) mas não há bloco `database_encryption`/CMEK no `google_container_cluster.cluster` do `main.tf` que os utilize.
- O binding `google_project_iam_member.fleet_sa_gkehub_admin` usa um SA fixo hardcoded (`service-373570785065@gcp-sa-gkenode.iam.gserviceaccount.com`) em vez do `local.fleet_sa[each.key]` calculado a partir do projeto de cada cluster — vale revisar se isso é intencional ao reutilizar o módulo em outro projeto.
