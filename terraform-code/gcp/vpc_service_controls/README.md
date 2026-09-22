# vpc_service_controls

Módulo Terraform responsável por criar **regras de ingress e egress** (`google_access_context_manager_service_perimeter_ingress_policy` / `..._egress_policy`) num **Service Perimeter do VPC Service Controls já existente**, a partir de dois mapas de configuração independentes. Segue o mesmo padrão `for_each` sobre mapa dos demais módulos deste repositório (ex.: `service_account`, `pubsub`).

Este módulo **não cria nem gerencia o perímetro em si** — nem a lista de projetos/recursos protegidos, nem os `restricted_services`, nem os access levels. Isso já é feito fora do Terraform hoje (ver `gcp-landing-zone.yaml`, step "Adicionar ao Perímetro de Acesso", via `gcloud access-context-manager perimeters update --add-resources`). Este módulo só anexa **regras de ingress/egress** a um perímetro que já existe, referenciado por `access_policy_id` + `perimeter_name` — **dentro de cada regra**, não como configuração única do módulo (ver "Por que `access_policy_id`/`perimeter_name` ficam dentro de cada regra" abaixo).

## Por que regras dedicadas (`_ingress_policy`/`_egress_policy`) e não o perímetro inteiro

A API do GCP para VPC Service Controls também permite configurar ingress/egress como blocos dentro do recurso `google_access_context_manager_service_perimeter` (a definição completa do perímetro). Esse caminho foi propositalmente evitado aqui: esse recurso é **autoritativo sobre a definição inteira** do perímetro — cada `apply` reescreve toda a lista de recursos, access levels e regras de uma vez. Como o perímetro deste ambiente (`perimetroprojetoscaixa`) é compartilhado entre times/processos diferentes (o próprio `gcp-landing-zone.yaml` já mexe na lista de recursos dele via `gcloud`), usar o recurso autoritativo aqui geraria disputa de state/drift a cada `apply`.

`google_access_context_manager_service_perimeter_ingress_policy`/`_egress_policy` resolvem isso: cada regra é um **objeto independente** na API do Access Context Manager, criado/atualizado/removido sem tocar nas demais regras nem na definição do perímetro. Múltiplos times podem gerenciar regras no mesmo perímetro, cada um com seu próprio `state`, sem conflito.

## Por que `access_policy_id`/`perimeter_name` ficam dentro de cada regra

Esses dois campos existem em **cada item** de `ingress_policies`/`egress_policies` (com default para `"412713748361"`/`"perimetroprojetoscaixa"`, o perímetro único usado hoje), em vez de serem uma única variável do módulo. Decisão deliberada: quem escreve uma regra precisa declarar explicitamente qual política/perímetro ela afeta, mesmo quando é o default — evita ficar "solto" fora da regra, onde seria fácil perder de vista qual perímetro está sendo alterado ao ler só o `ingress_policies`/`egress_policies`. Também deixa o módulo pronto para gerenciar regras em mais de um perímetro numa mesma chamada, se um dia isso for necessário, sem precisar de uma segunda instância do módulo.

## Recursos criados

- `google_access_context_manager_service_perimeter_ingress_policy.rule` — uma regra de ingress por chave de `var.ingress_policies`.
- `google_access_context_manager_service_perimeter_egress_policy.rule` — uma regra de egress por chave de `var.egress_policies`.

## Como usar

```hcl
module "vpc_service_controls" {
  source = "./gcp/vpc_service_controls"

  egress_policies = {
    acesso-cmek-hsm-prd = {
      access_policy_id = "412713748361"
      perimeter_name   = "perimetroprojetoscaixa"

      egress_from = {
        identity_type = "ANY_SERVICE_ACCOUNT"
      }
      egress_to = {
        resources = ["projects/999999999999"] # project NUMBER, não project_id
        operations = [
          {
            service_name = "cloudkms.googleapis.com"
            method_selectors = [
              { method = "*" },
            ]
          }
        ]
      }
    }
  }

  ingress_policies = {
    cicd-acessa-bigquery = {
      # access_policy_id/perimeter_name omitidos de propósito -- caem no default
      # (o mesmo perímetro "412713748361"/"perimetroprojetoscaixa" do egress acima)
      ingress_from = {
        identity_type = "ANY_SERVICE_ACCOUNT"
        identities    = ["serviceAccount:sa-cicd@prj-cicd-prd.iam.gserviceaccount.com"]
        sources = [
          { resource = "projects/111111111111" }, # project NUMBER, não project_id
        ]
      }
      ingress_to = {
        resources = ["*"]
        operations = [
          {
            service_name = "bigquery.googleapis.com"
            method_selectors = [
              { method = "*" },
            ]
          }
        ]
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `ingress_policies` | Mapa de regras de ingress a criar | `map(object({...}))` | `{}` | não |
| `egress_policies` | Mapa de regras de egress a criar | `map(object({...}))` | `{}` | não |

### Estrutura de cada item de `ingress_policies`

| Atributo | Tipo | Default | Descrição |
|----------|------|---------|-----------|
| `title` | `string` | chave do mapa | Título da regra no console/API |
| `access_policy_id` | `string` | `"412713748361"` | ID numérico da Access Policy onde o perímetro desta regra vive |
| `perimeter_name` | `string` | `"perimetroprojetoscaixa"` | Nome do Service Perimeter já existente ao qual esta regra será anexada |
| `ingress_from.identity_type` | `string` | `"ANY_IDENTITY"` | `ANY_IDENTITY`, `ANY_USER_ACCOUNT` ou `ANY_SERVICE_ACCOUNT` — quem pode entrar. Use `ANY_IDENTITY` só junto com `identities` vazio quando realmente quiser liberar geral; o normal é `ANY_SERVICE_ACCOUNT`/`ANY_USER_ACCOUNT` + `identities` preenchido |
| `ingress_from.identities` | `list(string)` | `[]` | Identidades específicas liberadas (`"serviceAccount:..."`, `"user:..."`), no formato completo do GCP |
| `ingress_from.sources` | `list(object({ access_level, resource }))` | `[]` | De onde o tráfego pode vir. Cada item tem **access_level OU resource**, nunca os dois (validado pelo módulo). `resource` é `"projects/<PROJECT_NUMBER>"` — **número do projeto, não o `project_id`** |
| `ingress_to.resources` | `list(string)` | — (obrigatório) | Recursos alvo dentro do perímetro: `["*"]` para todos, ou `["projects/<PROJECT_NUMBER>"]` |
| `ingress_to.roles` | `list(string)` | `[]` | Restringe a regra a chamadas feitas sob essas roles do IAM (opcional) |
| `ingress_to.operations` | `list(object({ service_name, method_selectors }))` | — (obrigatório) | Serviços/métodos liberados. `service_name`: ex. `"bigquery.googleapis.com"` ou `"*"`. `method_selectors`: lista de `{ method }` OU `{ permission }` — nunca os dois no mesmo item |

### Estrutura de cada item de `egress_policies`

| Atributo | Tipo | Default | Descrição |
|----------|------|---------|-----------|
| `title` | `string` | chave do mapa | Título da regra no console/API |
| `access_policy_id` | `string` | `"412713748361"` | ID numérico da Access Policy onde o perímetro desta regra vive |
| `perimeter_name` | `string` | `"perimetroprojetoscaixa"` | Nome do Service Perimeter já existente ao qual esta regra será anexada |
| `egress_from.identity_type` | `string` | `"ANY_IDENTITY"` | Mesma semântica do ingress |
| `egress_from.identities` | `list(string)` | `[]` | Mesma semântica do ingress |
| `egress_from.source_restriction` | `string` | `null` | `SOURCE_RESTRICTION_ENABLED` ou `SOURCE_RESTRICTION_DISABLED` — restringe a regra a `sources` específicos quando habilitado |
| `egress_from.sources` | `list(object({ access_level, resource }))` | `[]` | Mesma semântica do ingress (access_level OU resource, validado) |
| `egress_to.resources` | `list(string)` | — (obrigatório) | Recursos alvo fora do perímetro: `["*"]` ou `["projects/<PROJECT_NUMBER>"]` |
| `egress_to.external_resources` | `list(string)` | `[]` | Recursos totalmente fora do GCP (buckets S3, etc.) liberados para a regra |
| `egress_to.roles` | `list(string)` | `[]` | Mesma semântica do ingress |
| `egress_to.operations` | `list(object({ service_name, method_selectors }))` | — (obrigatório) | Mesma semântica do ingress |

## Outputs

| Nome | Descrição |
|------|-----------|
| `ingress_policy_ids` | ID de cada regra de ingress criada, indexado pela mesma chave de `ingress_policies` |
| `ingress_policy_perimeters` | Resource name completo do perímetro alvo de cada regra de ingress (`accessPolicies/<access_policy_id>/servicePerimeters/<perimeter_name>`), indexado pela mesma chave de `ingress_policies` |
| `egress_policy_ids` | ID de cada regra de egress criada, indexado pela mesma chave de `egress_policies` |
| `egress_policy_perimeters` | Resource name completo do perímetro alvo de cada regra de egress, indexado pela mesma chave de `egress_policies` |

## Observações

- **Projetos são referenciados por NÚMERO, não por `project_id`.** Em `ingress_from.sources[].resource` e em `*.resources`, o formato é `"projects/<PROJECT_NUMBER>"` (o número, ex. `"projects/123456789012"`) — usar o `project_id` (string) nesses campos é rejeitado pela API. Isso é uma pegadinha comum de VPC Service Controls, diferente da maioria dos outros recursos do GCP que aceitam `project_id`.
- **`method` vs `permission` em `method_selectors`**: mutuamente exclusivos por item — ou você lista métodos específicos (`method = "google.storage.objects.get"`), ou usa `permission = "*"` (ou uma permission específica) para liberar tudo daquele tipo. Misturar os dois no mesmo item da lista é rejeitado pela API.
- **`sources[].access_level` vs `sources[].resource`**: também mutuamente exclusivos por item — o módulo valida isso em `variables.tf` (erro de `validation` antes mesmo de chamar a API se algum item tiver os dois ou nenhum preenchido).
- Este módulo não cria o Access Level referenciado em `access_level` (quando usado) — ele precisa já existir na Access Policy (`access_policy_id`), criado fora deste módulo.
- Quem roda o `apply` precisa da role `roles/accesscontextmanager.policyEditor` (ou equivalente) na Access Policy — não é concedida por este módulo.
- Como cada regra é seu próprio objeto na API, apagar uma entrada do mapa (`ingress_policies`/`egress_policies`) remove só aquela regra especificamente, sem afetar as demais nem a definição do perímetro.
- Requer o provider `google` (não precisa de `google-beta`) numa versão que suporte esses dois resources — confirmado com `hashicorp/google` v8.3.0 neste módulo.
