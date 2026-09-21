# pubsub

Módulo Terraform responsável por provisionar tópicos e assinaturas (subscriptions) do Google Cloud Pub/Sub. Ele permite criar, a partir de dois mapas de configuração independentes, N tópicos e N assinaturas em um ou mais projetos GCP, padronizando a nomenclatura dos recursos com base na chave do mapa, uma sigla e o workspace do Terraform.

## Recursos criados

- `google_pubsub_topic.topic` — cria um tópico Pub/Sub para cada chave do mapa `var.pubsub_topic_settings`.
- `google_pubsub_subscription.subs` — cria uma assinatura Pub/Sub para cada chave do mapa `var.pubsub_settings`, vinculada ao tópico indicado em `topic_name`.
- `google_project_service_identity.pubsub` — *(só com CMEK)* service agent do Pub/Sub, por projeto.
- `google_kms_crypto_key_iam_member.pubsub` — *(só com CMEK)* concede `roles/cloudkms.cryptoKeyEncrypterDecrypter` na chave ao service agent, um binding por combinação projeto+chave.

## Como usar

```hcl
module "pubsub" {
  source = "./gcp/pubsub"

  pubsub_topic_settings = {
    "pst" = {
      project_id = "meu-projeto-gcp"
      sigla      = "sqa"
      labels = {
        ambiente = "producao"
      }
    }

    # exemplo com CMEK
    "pst-cmek" = {
      project_id     = "meu-projeto-gcp"
      sigla          = "sqa"
      labels = {
        ambiente = "producao"
      }
      kms_project_id = "prj-hsm-services-prd"
      region         = "southamerica-east1"
      kms_key_ring   = "infrahsmPRDring"
      kms_crypto_key = "infraPRDSYMAES256hsm001"
    }
  }

  pubsub_settings = {
    "pss" = {
      project_id                 = "meu-projeto-gcp"
      topic_name                 = "pst-sqa-prd"
      ack_deadline_seconds       = 20
      message_retention_duration = "1200s"
      retain_acked_messages      = true
      sigla                      = "sqa"
      labels = {
        ambiente = "producao"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `pubsub_topic_settings` | Mapa de tópicos a serem criados. A chave do mapa é usada como parte do nome do tópico. `project_id` é o projeto onde o tópico será criado, `sigla` é um sufixo de nomenclatura, `labels` são rótulos livres e `kms_project_id`/`region`/`kms_key_ring`/`kms_crypto_key` (opcionais, todos juntos ou nenhum) definem a chave CMEK usada para criptografar as mensagens do tópico — `region` aqui é a location da chave KMS (tópico Pub/Sub em si não é regional). | `map(object({ project_id = string, sigla = string, labels = map(any), kms_project_id = optional(string), region = optional(string), kms_key_ring = optional(string), kms_crypto_key = optional(string) }))` | — | Sim |
| `pubsub_settings` | Mapa de assinaturas (subscriptions) a serem criadas. A chave do mapa é usada como parte do nome da assinatura. `project_id` é o projeto onde a assinatura será criada, `topic_name` é o nome completo do tópico ao qual ela se vincula, `ack_deadline_seconds`, `message_retention_duration` e `retain_acked_messages` configuram o comportamento de entrega/retenção, `sigla` é um sufixo de nomenclatura e `labels` são rótulos aplicados à assinatura. | `map(object({ project_id = string, topic_name = string, ack_deadline_seconds = number, message_retention_duration = string, retain_acked_messages = optional(bool, true), sigla = string, labels = map(any) }))` | — | Sim |

## Outputs

| Nome | Descrição |
|------|-----------|
| `pubsub_topics` | Mapa (mesma chave de `pubsub_topic_settings`) com `id`, `name`, `project` e `kms_key_name` de cada tópico criado |
| `pubsub_subscriptions` | Mapa (mesma chave de `pubsub_settings`) com `id`, `name`, `project` e `topic` de cada assinatura criada |

## Observações

- O nome final de cada recurso segue o padrão `${chave}-${sigla}-${terraform.workspace}`, garantindo unicidade entre workspaces (ex.: dev/hml/prd).
- `google_pubsub_subscription.subs` depende explicitamente de `google_pubsub_topic.topic` (`depends_on`), mas essa dependência só é efetiva de fato quando o tópico referenciado em `topic_name` é criado pelo mesmo `apply` — o campo `topic` da assinatura é uma string livre, não uma referência direta ao recurso `google_pubsub_topic`, então nada impede apontar para um tópico já existente fora deste módulo.
- Os mapas `pubsub_topic_settings` e `pubsub_settings` são independentes: é possível criar tópicos sem assinaturas (ou vice-versa) e não há vínculo automático de chaves entre os dois mapas — a ligação é feita manualmente via `topic_name`.
- CMEK fica só no tópico — o Pub/Sub não tem CMEK por assinatura; a assinatura herda a criptografia do tópico ao qual está vinculada. O módulo monta o `kms_key_name` concatenando `kms_project_id`, `region`, `kms_key_ring` e `kms_crypto_key` (`local.pubsub_topic_kms_key_names` em `topic.tf`) — uma `validation` em `variables.tf` garante que os 4 sejam preenchidos juntos (ou nenhum, usando a chave gerenciada pelo Google). CMEK é opcional: sem `kms_*` em nenhum tópico, o módulo não cria nenhum recurso de IAM/service identity e nada muda no `plan`.
- **Permissão na chave (criada pelo módulo quando há CMEK)**: para cada projeto com tópico CMEK, o módulo cria o service agent do Pub/Sub (`google_project_service_identity`, `service-<PROJECT_NUMBER>@gcp-sa-pubsub.iam.gserviceaccount.com`) e concede a ele `roles/cloudkms.cryptoKeyEncrypterDecrypter` na chave (`google_kms_crypto_key_iam_member`, em `iam.tf`); o tópico tem `depends_on` nesse binding. Tópicos do mesmo projeto com a mesma chave compartilham um único binding. `google_project_service_identity` exige o provider `google-beta` na stack, e quem roda o `apply` precisa poder conceder IAM na chave KMS. Se o primeiro `apply` falhar por acesso à chave logo após criar o binding, aguarde a propagação e rode de novo.
- **Corrigido**: até a versão anterior deste módulo, `google_pubsub_subscription.subs` ignorava `ack_deadline_seconds`, `message_retention_duration` e `retain_acked_messages` do input e usava constantes fixas no código (`20`, `"1200s"`, `true`). Agora o recurso usa os valores de `each.value` — se algum ambiente já provisionado tinha esses valores diferentes dos defaults antigos no seu `tfvars`, o próximo `apply` vai gerar diff nessas assinaturas, alinhando ao valor que sempre deveria ter sido aplicado.
- O tópico também passou a aplicar `labels` (estava declarado como obrigatório em `pubsub_topic_settings` mas não era usado no recurso) — mesmo tipo de diff pode aparecer em tópicos já existentes que tinham `labels` preenchido no tfvars.
