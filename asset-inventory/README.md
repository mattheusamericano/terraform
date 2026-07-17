# Inventário GCP com Cloud Asset Inventory + BigQuery + Views

Exemplo funcional de arquitetura para inventário centralizado de recursos GCP,
usando Cloud Asset Inventory (CAI) como fonte, BigQuery como repositório e
views para consultas rápidas.

## Arquitetura

```
Cloud Asset Inventory (org/folder/project)
        │  exportAssets (resource + iam-policy), particionado por request-time
        ▼
BigQuery dataset "asset_inventory"
   ├─ inventory_resources   (tabela particionada, 1 partição por execução)
   └─ inventory_iam_policies
        │
        ▼
Views (views.sql)
   ├─ v_inventory_latest          → snapshot mais recente, "achatado"
   ├─ v_resources_by_project_type → contagem por projeto/tipo/região
   ├─ v_untagged_resources        → recursos sem labels obrigatórias
   └─ v_iam_bindings_flat         → bindings de IAM em formato tabular
        │
        ▼
Looker Studio (dashboard) conectado direto nas views
```

Cloud Scheduler dispara a exportação todo dia — assim cada partição da tabela é
um snapshot histórico, e as views sempre leem o snapshot mais recente.

## Arquivos

- `01_setup_dataset.sh` — habilita APIs e cria o dataset no BigQuery.
- `02_export_once.sh` — roda a exportação manualmente uma vez (bom para testar).
- `03_schedule_daily_export.sh` — empacota o export num Cloud Run Job e agenda
  execução diária via Cloud Scheduler.
- `views.sql` — as views de consulta.

## Passo a passo

1. Ajuste as variáveis no topo de cada script (`ORG_ID`, `PROJECT_ID`, `REGION`).
2. Rode `01_setup_dataset.sh`.
3. Rode `02_export_once.sh` para validar que os dados chegam certo no BigQuery.
4. Rode `03_schedule_daily_export.sh` para automatizar (execução diária às 06:00).
5. No BigQuery, rode `views.sql` para criar as views.
6. Conecte o Looker Studio na tabela `v_inventory_latest` e nas demais views
   (BigQuery connector nativo, sem custo adicional).

## Permissões necessárias

- No nível de organização/pasta/projeto que será inventariado:
  `roles/cloudasset.viewer` para a service account que executa o export.
- No dataset do BigQuery: `roles/bigquery.dataEditor` para a mesma service
  account (o script `01_setup_dataset.sh` já concede isso).

## Extensões possíveis

- Juntar com a exportação de Billing para BigQuery → custo por recurso.
- Juntar com Security Command Center findings export → recursos com
  vulnerabilidades abertas.
- Trocar Cloud Run Job por Cloud Function acionada por feed do CAI
  (Pub/Sub) para ter atualização quase em tempo real em vez de diária.

## Fontes usadas para validar sintaxe

- [Export asset metadata to BigQuery](https://docs.cloud.google.com/asset-inventory/docs/export-bigquery)
- [gcloud asset export reference](https://docs.cloud.google.com/sdk/gcloud/reference/asset/export)
- [Monitor asset changes with Pub/Sub](https://docs.cloud.google.com/asset-inventory/docs/monitor-asset-changes)
