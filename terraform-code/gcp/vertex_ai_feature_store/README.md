# vertex_ai_feature_store

Módulo que provisiona um **Vertex AI Feature Store** (`google_ai_platform_featurestore`) com criptografia CMEK obrigatória, concedendo automaticamente ao Service Agent do Vertex AI a permissão necessária na chave KMS.

## Recursos criados

- `google_ai_platform_featurestore.featurestore` — o Feature Store. Nome final composto como `<chave>-<sigla>-<workspace>`. Configurado com `online_serving_config.fixed_node_count = 1` (nó único fixo para serving online) e `encryption_spec` apontando para uma chave CMEK.
- `google_kms_crypto_key_iam_member.featurestore_kms` — concede `roles/cloudkms.cryptoKeyEncrypterDecrypter` ao Service Agent do Vertex AI (`service-<PROJECT_NUMBER>@gcp-sa-aiplatform.iam.gserviceaccount.com`) na chave KMS usada pelo Feature Store.
- `data.google_project.project` — usado para obter o número do projeto (necessário para montar o e-mail do Service Agent do Vertex AI).

## Como usar

```hcl
module "vertex_ai_feature_store" {
  source = "./gcp/vertex_ai_feature_store"

  feature_store_settings = {
    fs_scoring_cliente = {
      project_id      = "prj-ml-plataforma-prd"
      region          = "southamerica-east1"
      sigla           = "sipml"
      kms_project_id  = "prj-kms"
      key_ring        = "vertex-ai-kr"
      key_crypto      = "vertex-ai-key"
      labels = {
        camada = "ml"
        uso    = "feature-store"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `feature_store_settings` | Mapa de configuração dos Feature Stores. Cada chave representa um Feature Store lógico. | `map(object({...}))` | — | Sim |

Campos do objeto (`feature_store_settings["<chave>"]`):

| Campo | Descrição | Tipo | Default | Obrigatório |
|-------|-----------|------|---------|:-----------:|
| `project_id` | Projeto onde o Feature Store será criado | `string` | — | Sim |
| `region` | Região do Feature Store | `string` | — | Sim |
| `sigla` | Sigla usada na composição do nome do Feature Store | `string` | — | Sim |
| `kms_project_id` | Projeto onde vive a chave KMS usada para CMEK | `string` | — | Sim |
| `key_ring` | Key ring da chave KMS | `string` | — | Sim |
| `key_crypto` | Nome da chave KMS (crypto key) | `string` | — | Sim |
| `labels` | Labels aplicadas ao Feature Store | `map(any)` | — | Sim |

## Outputs

| Nome | Descrição |
|------|-----------|
| `feature_store_ids` | Mapa chave => ID do Feature Store criado |

## Observações

- **CMEK é obrigatório, não opcional**: diferente de outros módulos deste repositório (como `cloud_run` ou `vertex_ai_feature_store`), aqui todos os campos de KMS (`kms_project_id`, `key_ring`, `key_crypto`) são obrigatórios — não há suporte a Feature Store sem CMEK.
- **Ordem de criação**: o Feature Store depende explicitamente (`depends_on`) do binding de IAM na chave KMS, garantindo que o Service Agent do Vertex AI já tenha permissão de uso da chave antes da criação do recurso — evita erro de permissão negada durante o provisionamento.
- **Capacidade fixa**: `fixed_node_count = 1` está hardcoded em `main.tf` — não há variável para ajustar o número de nós de serving online; qualquer mudança de capacidade exige editar o módulo diretamente.
- **Sem outputs de nome/URI**: apenas o `id` do recurso é exposto; se precisar do nome completo (`projects/.../featurestores/...`) para uso em outros recursos, use o próprio `id` ou adicione um output adicional.
