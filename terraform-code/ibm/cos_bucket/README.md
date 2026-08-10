# cos_bucket

Módulo que provisiona **buckets do IBM Cloud Object Storage (COS)** dentro de uma instância já existente, incluindo classe de armazenamento, localização, CMEK, versionamento, retenção, activity tracking, métricas e IAM restrito ao bucket. É o módulo "filho" na dupla [`cos_instance`](../cos_instance/README.md) + `cos_bucket` — a instância é criada pelo outro módulo, e o CRN/GUID reais dela são passados para cá via output.

## Recursos criados

- `ibm_cos_bucket.this` — o bucket COS. Nome final composto como `<chave>-<sigla>-<workspace>`. Suporta localização regional, cross-region ou single-site (apenas uma das três), classe de armazenamento, CMEK via `kms_key_crn`, cota rígida (`hard_quota`), lista de IPs permitidos, Object Lock e tipo de endpoint (público/privado/direto).
  - Bloco `object_versioning` sempre presente (habilitado/desabilitado via `object_versioning_enabled`).
  - Blocos dinâmicos `retention_rule`, `activity_tracking` e `metrics_monitoring`, criados apenas quando os respectivos objetos são informados.
- `ibm_iam_access_group_policy.manager` / `.writer` / `.reader` — bindings de IAM **restritos a este bucket** (`resource_type = "bucket"` + nome real do bucket), concedendo os papéis `Manager`, `Writer` e `Reader` a access groups, sem afetar outros buckets da mesma instância COS.

## Como usar

```hcl
module "cos_bucket" {
  source = "./ibm/cos_bucket"

  cos_bucket_settings = {
    cache_decisao = {
      sigla         = "sipml"
      instance_crn  = module.cos_instance.instance_crns["hub_decision_broker"]
      instance_guid = module.cos_instance.instance_guids["hub_decision_broker"]

      location_type = "region"
      location      = "br-sao"
      storage_class = "standard"
      endpoint_type = "private"

      object_versioning_enabled = true

      retention_rule = {
        default = 30
        maximum = 365
        minimum = 1
      }

      # Opcional: CMEK. A chave precisa pertencer a uma instancia ja
      # autorizada via kms_instance_guid no modulo cos_instance.
      kms_key_crn = "crn:v1:bluemix:public:kms:us-south:a/1234567890abcdef1234567890abcdef:z9y8x7w6-v5u4-3210-tsrq-ponmlkjihgfe:key:11112222-3333-4444-5555-666677778888"

      iam_bindings = {
        managers = ["AccessGroupId-1111aaaa-2222-bbbb-3333-cccc4444dddd"]
        writers  = ["AccessGroupId-5555eeee-6666-ffff-7777-gggg8888hhhh"]
        readers  = ["AccessGroupId-9999iiii-0000-jjjj-1111-kkkk2222llll"]
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `cos_bucket_settings` | Mapa de configuração dos buckets COS. Cada chave representa um bucket lógico dentro de uma instância. | `map(object({...}))` | — | Sim |

Campos do objeto (`cos_bucket_settings["<chave>"]`):

| Campo | Descrição | Tipo | Default | Obrigatório |
|-------|-----------|------|---------|:-----------:|
| `sigla` | Sigla usada na composição do nome do bucket | `string` | — | Sim |
| `instance_crn` | CRN da instância COS (`instance_crns` do módulo `cos_instance`) | `string` | — | Sim |
| `instance_guid` | GUID da instância COS (`instance_guids` do módulo `cos_instance`), usado para escopar o IAM no bucket | `string` | — | Sim |
| `location_type` | Tipo de localização: `"region"`, `"cross_region"` ou `"single_site"` — define qual campo de localização do recurso é preenchido | `string` | — | Sim |
| `location` | Valor da localização correspondente a `location_type` (ex: `"br-sao"`, `"us"`, `"sao01"`) | `string` | — | Sim |
| `storage_class` | Classe de armazenamento: `standard`, `vault`, `cold`, `smart` ou `onerate_active` | `string` | `"standard"` | Não |
| `endpoint_type` | Tipo de endpoint: `public`, `private` ou `direct` | `string` | `"public"` | Não |
| `force_delete` | Se `true`, apaga todos os objetos do bucket antes de destruí-lo via Terraform | `bool` | `true` | Não |
| `hard_quota` | Cota máxima de armazenamento, em bytes | `number` | `null` | Não |
| `allowed_ip` | Lista de CIDRs (IPv4/IPv6) com acesso permitido ao bucket | `list(string)` | `null` | Não |
| `object_lock` | Habilita proteção via Object Lock | `bool` | `false` | Não |
| `object_versioning_enabled` | Habilita versionamento de objetos | `bool` | `false` | Não |
| `kms_key_crn` | CRN da chave Key Protect/HPCS para CMEK | `string` | `null` | Não |
| `retention_rule.default` | Dias de retenção aplicados por padrão a novos objetos | `number` | — (obrigatório se `retention_rule` for informado) | Não |
| `retention_rule.maximum` | Retenção máxima permitida, em dias | `number` | — | Não |
| `retention_rule.minimum` | Retenção mínima permitida, em dias | `number` | — | Não |
| `retention_rule.permanent` | Se `true`, habilita retenção permanente (nenhum objeto pode ser excluído) | `bool` | `false` | Não |
| `activity_tracking.read_data_events` | Rastreia eventos de leitura de objetos | `bool` | `false` | Não |
| `activity_tracking.write_data_events` | Rastreia eventos de escrita de objetos | `bool` | `false` | Não |
| `activity_tracking.management_events` | Rastreia eventos de gerenciamento do bucket | `bool` | `false` | Não |
| `activity_tracking.activity_tracker_crn` | CRN da instância do Activity Tracker de destino | `string` | `null` | Não |
| `metrics_monitoring.usage_metrics_enabled` | Habilita métricas de uso (armazenamento/contagem de objetos) | `bool` | `false` | Não |
| `metrics_monitoring.request_metrics_enabled` | Habilita métricas de requisições | `bool` | `false` | Não |
| `metrics_monitoring.metrics_monitoring_crn` | CRN da instância do IBM Cloud Monitoring de destino | `string` | `null` | Não |
| `iam_bindings.managers` | IDs de access group com papel `Manager`, restrito a este bucket | `list(string)` | `[]` | Não |
| `iam_bindings.writers` | IDs de access group com papel `Writer`, restrito a este bucket | `list(string)` | `[]` | Não |
| `iam_bindings.readers` | IDs de access group com papel `Reader`, restrito a este bucket | `list(string)` | `[]` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `bucket_ids` | Mapa chave => ID do bucket criado |
| `bucket_crns` | Mapa chave => CRN do bucket criado |
| `bucket_names` | Mapa chave => nome real do bucket criado |
| `s3_endpoints_public` | Mapa chave => endpoint S3 público do bucket |
| `s3_endpoints_private` | Mapa chave => endpoint S3 privado do bucket |

## Observações

- **Preencha exatamente um `location_type`**: o módulo seta `region_location`, `cross_region_location` e `single_site_location` de forma mutuamente exclusiva com base em `location_type` — os outros dois ficam `null` automaticamente. Só é possível escolher a localização na criação do bucket; não é possível migrar depois.
- **Nome do bucket é único globalmente**: assim como no S3, o `bucket_name` precisa ser único em **todo o IBM Cloud**, não só na conta. Escolha `sigla`/chave com cuidado para evitar colisão entre projetos e ambientes.
- **CMEK depende do `cos_instance`**: para usar `kms_key_crn`, a instância COS dona deste bucket precisa já ter sido autorizada a acessar a instância de KMS correspondente via `kms_instance_guid` no módulo `cos_instance` — caso contrário a criação do bucket falha por falta de permissão.
- **IAM restrito ao bucket, não à instância**: os bindings aqui usam `resource_type = "bucket"` e `resource = <nome do bucket>`, então só valem para este bucket específico — para dar acesso a todos os buckets de uma instância, use `iam_bindings` no módulo `cos_instance`.
- **Bindings são aditivos**: `ibm_iam_access_group_policy` não é autoritativo — adiciona a política ao access group sem remover outras políticas existentes.
- **`force_delete = true` por padrão**: diferente do padrão mais conservador usado em outros módulos deste repositório (ex: `deletion_protection = true` no Spanner), aqui o default do provider IBM apaga o conteúdo do bucket junto com o bucket. Ajuste para `false` em buckets de produção/auditoria caso queira proteção extra.
- Veja `example.tfvars` no diretório do módulo para um exemplo completo de `tfvars`, incluindo um bucket regional com retenção e um bucket cross-region com Object Lock.
