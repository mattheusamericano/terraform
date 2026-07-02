# dataplex_knowledge_catalog_zone

Módulo Terraform responsável por provisionar **zones** do Dataplex (Universal Catalog) dentro de um lake já existente. Uma zone define uma área lógica de organização de dados (tipicamente `RAW` ou `CURATED`) com regras de descoberta automática de assets (discovery) e especificação de armazenamento. É a camada intermediária entre o Dataplex Lake e os Assets (buckets/datasets) que serão descobertos e catalogados.

## Recursos criados

- `google_dataplex_zone.zone` — cria uma zone do Dataplex para cada entrada do mapa `dataplex_zone_settings`, associada a um lake (`lake_key`), com tipo (`RAW`/`CURATED`), especificação de localização (`resource_spec`) e configuração de descoberta automática (`discovery_spec`), incluindo suporte opcional a delimitador CSV.

## Como usar

```hcl
module "dataplex_knowledge_catalog_zone" {
  source = "./gcp/dataplex_knowledge_catalog_zone"

  dataplex_zone_settings = {
    raw = {
      lake_key            = "lake-dados"
      project_id          = "meu-projeto-gcp"
      region              = "us-central1"
      sigla               = "eng"
      zone_type           = "RAW"
      location_type       = "SINGLE_REGION"
      discovery_enabled   = true
      discovery_schedule  = "0 6 * * *"
      csv_delimiter       = ";"
      labels = {
        ambiente = "prd"
        squad    = "engenharia-dados"
      }
    }
    curated = {
      lake_key           = "lake-dados"
      project_id         = "meu-projeto-gcp"
      region             = "us-central1"
      sigla              = "eng"
      zone_type          = "CURATED"
      discovery_enabled  = true
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `dataplex_zone_settings` | Mapa de zones a serem criadas. Cada chave do mapa vira parte do nome/display_name da zone. | `map(object({ lake_key=string, project_id=string, region=string, sigla=string, zone_type=string, location_type=optional(string,"SINGLE_REGION"), discovery_enabled=optional(bool,true), discovery_schedule=optional(string,"0 6 * * *"), csv_delimiter=optional(string,null), labels=optional(map(string),{}) }))` | — | sim |

### Estrutura de `dataplex_zone_settings`

Cada entrada do mapa representa uma zone e deve conter:

- `lake_key` — chave usada para resolver o lake pai (referenciada como `lake` no recurso).
- `project_id` — projeto onde a zone será criada.
- `region` — região (`location`) do lake/zone.
- `sigla` — sigla do time/domínio, usada na composição do nome (`display_name`).
- `zone_type` — `RAW` ou `CURATED`; define tanto o `type` do recurso quanto parte do nome gerado.
- `location_type` (opcional, default `SINGLE_REGION`) — tipo de localização do `resource_spec`.
- `discovery_enabled` (opcional, default `true`) — habilita a descoberta automática de assets na zone.
- `discovery_schedule` (opcional, default `"0 6 * * *"`) — cron da descoberta automática.
- `csv_delimiter` (opcional, default `null`) — se definido, configura o delimitador de arquivos CSV no `discovery_spec` (bloco dinâmico `csv_options`).
- `labels` (opcional, default `{}`) — labels aplicadas à zone.

## Outputs

| Nome | Descrição |
|------|-----------|
| `ids` | IDs das zones criadas, indexados pela chave do mapa `dataplex_zone_settings`. |
| `names` | Nomes das zones criadas, indexados pela chave do mapa — usado pelo módulo `dataplex-asset`. |

## Observações

- O nome final da zone é gerado automaticamente como `zone-<zone_type em minúsculo>-<chave do mapa>`, e o `display_name` como `Zone <ZONE_TYPE> - <CHAVE>` (ambos em maiúsculo). Não é possível definir um nome customizado diretamente.
- O módulo não cria o Lake nem o Asset — ele depende de um lake já existente (identificado por `lake_key`), e o output `names` foi desenhado para ser consumido pelo módulo `dataplex-asset` na composição dos assets dentro da zone.
- O bloco `csv_options` só é incluído quando `csv_delimiter` é diferente de `null` (uso de `dynamic` block condicional).
- Todos os recursos são criados via `for_each` sobre `dataplex_zone_settings`, portanto cada chave do mapa deve ser única e estável entre execuções (evita recriação desnecessária dos recursos).
