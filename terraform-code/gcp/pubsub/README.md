# pubsub

Módulo Terraform responsável por provisionar tópicos e assinaturas (subscriptions) do Google Cloud Pub/Sub. Ele permite criar, a partir de dois mapas de configuração independentes, N tópicos e N assinaturas em um ou mais projetos GCP, padronizando a nomenclatura dos recursos com base na chave do mapa, uma sigla e o workspace do Terraform.

## Recursos criados

- `google_pubsub_topic.topic` — cria um tópico Pub/Sub para cada chave do mapa `var.pubsub_topic_settings`.
- `google_pubsub_subscription.subs` — cria uma assinatura Pub/Sub para cada chave do mapa `var.pubsub_settings`, vinculada ao tópico indicado em `topic_name`.

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
| `pubsub_topic_settings` | Mapa de tópicos a serem criados. A chave do mapa é usada como parte do nome do tópico. `project_id` é o projeto onde o tópico será criado, `sigla` é um sufixo de nomenclatura e `labels` são rótulos livres associados à configuração. | `map(object({ project_id = string, sigla = string, labels = map(any) }))` | — | Sim |
| `pubsub_settings` | Mapa de assinaturas (subscriptions) a serem criadas. A chave do mapa é usada como parte do nome da assinatura. `project_id` é o projeto onde a assinatura será criada, `topic_name` é o nome completo do tópico ao qual ela se vincula, `ack_deadline_seconds`, `message_retention_duration` e `retain_acked_messages` configuram o comportamento de entrega/retenção (ver Observações), `sigla` é um sufixo de nomenclatura e `labels` são rótulos aplicados à assinatura. | `map(object({ project_id = string, topic_name = string, ack_deadline_seconds = number, message_retention_duration = string, retain_acked_messages = optional(bool, true), sigla = string, labels = map(any) }))` | — | Sim |

## Outputs

Este módulo não define outputs.

## Observações

- O nome final de cada recurso segue o padrão `${chave}-${sigla}-${terraform.workspace}`, garantindo unicidade entre workspaces (ex.: dev/hml/prd).
- `google_pubsub_subscription.subs` depende explicitamente de `google_pubsub_topic.topic` (`depends_on`), mas essa dependência só é efetiva de fato quando o tópico referenciado em `topic_name` é criado pelo mesmo `apply` — o campo `topic` da assinatura é uma string livre, não uma referência direta ao recurso `google_pubsub_topic`, então nada impede apontar para um tópico já existente fora deste módulo.
- **Atenção**: embora `ack_deadline_seconds`, `message_retention_duration` e `retain_acked_messages` estejam declarados em `pubsub_settings` e sejam exigidos/aceitos como input, o recurso `google_pubsub_subscription.subs` atualmente **ignora esses valores** e usa constantes fixas no código (`ack_deadline_seconds = 20`, `message_retention_duration = "1200s"`, `retain_acked_messages = true`). Ou seja, os valores informados nessas três chaves não têm efeito prático até que o `main.tf` seja ajustado para consumi-los.
- Os mapas `pubsub_topic_settings` e `pubsub_settings` são independentes: é possível criar tópicos sem assinaturas (ou vice-versa) e não há vínculo automático de chaves entre os dois mapas — a ligação é feita manualmente via `topic_name`.
