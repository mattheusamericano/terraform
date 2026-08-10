# cos_instance

Módulo que provisiona **instâncias do IBM Cloud Object Storage (COS)**. É o módulo "pai" na dupla `cos_instance` + [`cos_bucket`](../cos_bucket/README.md), espelhando o mesmo padrão já usado em `gcp/spanner_instance` + `gcp/spanner_database`: a instância é criada aqui (1 instância pode conter N buckets), e os buckets dentro dela são criados pelo módulo `cos_bucket`, referenciando o CRN/GUID reais da instância via output.

## Recursos criados

- `ibm_resource_instance.this` — a instância COS. Nome final composto como `cos-<sigla>-<workspace>`. `location` é sempre `"global"` (padrão do serviço COS) e `service` é fixado em `"cloud-object-storage"`.
- `ibm_iam_authorization_policy.cos_kms` — autoriza a instância COS a usar chaves de uma instância Key Protect ou Hyper Protect Crypto Services (HPCS) já existente, concedendo `Reader` da instância COS sobre a instância de KMS. Criado apenas quando `kms_instance_guid` é informado.
- `ibm_iam_access_group_policy.manager` / `.writer` / `.reader` — bindings de IAM em **nível de instância** (valem para todos os buckets dela), concedendo os papéis `Manager`, `Writer` e `Reader` a access groups. Um resource por combinação (instância, access group).

## Como usar

```hcl
module "cos_instance" {
  source = "./ibm/cos_instance"

  cos_instance_settings = {
    hub_decision_broker = {
      sigla             = "sipml"
      resource_group_id = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
      plan              = "standard"
      tags              = ["camada:hub", "uso:decision-broker"]

      # Opcional: autoriza a instância a usar uma chave existente do Key Protect
      kms_service_name  = "kms"
      kms_instance_guid = "z9y8x7w6-v5u4-3210-tsrq-ponmlkjihgfe"

      iam_bindings = {
        managers = ["AccessGroupId-1111aaaa-2222-bbbb-3333-cccc4444dddd"]
        writers  = ["AccessGroupId-5555eeee-6666-ffff-7777-gggg8888hhhh"]
        readers  = []
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `cos_instance_settings` | Mapa de configuração das instâncias COS. Cada chave representa uma instância lógica. | `map(object({...}))` | — | Sim |

Campos do objeto (`cos_instance_settings["<chave>"]`):

| Campo | Descrição | Tipo | Default | Obrigatório |
|-------|-----------|------|---------|:-----------:|
| `sigla` | Sigla usada na composição do nome da instância | `string` | — | Sim |
| `resource_group_id` | Resource group do IBM Cloud onde a instância será criada | `string` | — | Sim |
| `plan` | Plano da instância COS (`lite`, `standard`, `cos-satellite`) | `string` | `"standard"` | Não |
| `location` | Localização da instância — COS é sempre `"global"` | `string` | `"global"` | Não |
| `tags` | Tags aplicadas à instância | `list(string)` | `[]` | Não |
| `kms_service_name` | Serviço de KMS a autorizar: `"kms"` (Key Protect) ou `"hs-crypto"` (HPCS) | `string` | `"kms"` | Não |
| `kms_instance_guid` | GUID da instância Key Protect/HPCS a autorizar para uso pela instância COS | `string` | `null` | Não |
| `iam_bindings.managers` | IDs de access group com papel `Manager` em toda a instância | `list(string)` | `[]` | Não |
| `iam_bindings.writers` | IDs de access group com papel `Writer` em toda a instância | `list(string)` | `[]` | Não |
| `iam_bindings.readers` | IDs de access group com papel `Reader` em toda a instância | `list(string)` | `[]` | Não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `instance_crns` | Mapa chave => CRN da instância COS. Usar como `instance_crn` no módulo `cos_bucket` |
| `instance_guids` | Mapa chave => GUID da instância COS. Usar como `instance_guid` no módulo `cos_bucket` (necessário para IAM em nível de bucket) |
| `instance_names` | Mapa chave => nome real da instância COS criada |

## Observações

- **Nomenclatura consistente com o padrão GCP do repositório**: o nome final segue `<prefixo-do-recurso>-<sigla>-<workspace>`, igual ao já usado em todos os módulos `gcp/*`.
- **Unicidade do nome**: diferente da maioria dos recursos GCP deste repositório, o **nome da instância COS não precisa ser globalmente único** (só único dentro da conta/resource group) — mas o nome do **bucket** (módulo `cos_bucket`) precisa ser único em todo o IBM Cloud, como no S3. Evite reaproveitar a mesma `sigla`/chave para buckets em contas ou ambientes diferentes.
- **IAM em duas camadas**: este módulo concede acesso em nível de **instância** (todos os buckets dela). Para restringir o acesso a um bucket específico, use `iam_bindings` no módulo `cos_bucket` — o binding lá é escopado com `resource_type = "bucket"` e não afeta os demais buckets da mesma instância.
- **Bindings são aditivos**: `ibm_iam_access_group_policy` não é autoritativo — adiciona a política ao access group sem remover outras políticas existentes (diferente do `google_*_iam_binding` autoritativo usado nos módulos Spanner do GCP).
- **Encadeamento com `cos_bucket`**: os outputs `instance_crns` e `instance_guids` devem ser passados como `instance_crn` e `instance_guid` no módulo `cos_bucket`, já que o bucket não pode ser criado sem a instância existir primeiro.
- Veja `example.tfvars` no diretório do módulo para um exemplo completo de `tfvars`.
