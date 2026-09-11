# arch-iam_new

Stack de arquitetura equivalente ao [`arch-iam`](../../arch-iam/stacks), reescrito para consumir o módulo [`iam_new`](../../../terraform-code/gcp/iam_new) em vez do `iam`. Diferenças estruturais principais:

1. Toda a configuração de "quem recebe o quê" fica centralizada e explícita neste stack, sem nada hardcoded dentro do módulo — ver o [README do `iam_new`](../../../terraform-code/gcp/iam_new/README.md).
2. **Este stack não cria nenhuma Service Account.** Só concede roles a identidades que já existem — grupos organizacionais (ML Engineer, ML Data Scientist, Data Engineer) e quaisquer outras SAs/grupos via `extra_group_role_bindings`. Quem precisar de uma SA nova usa o módulo [`service_account`](../../../terraform-code/gcp/service_account) separadamente, como qualquer outro consumidor desse módulo.
3. As roles concedidas a cada perfil organizacional são **roles predefinidas do GCP**, não custom roles — a política de quais roles cada perfil recebe (e a distinção nprod × prod) vive dentro do módulo `iam_new` (`ml_ops_profiles.tf`), não neste stack. `iam_new` não cria nenhuma custom role (ver README daquele módulo) — este stack, consequentemente, também não cria mais nenhuma.

## Organização dos arquivos

- **`backend.tf`** / **`providers.tf`** — usam os tokens `__project_id__`/`__region__`/`__state-bucket__`/`__backend-prefix__` substituídos pelo pipeline.
- **`variables.tf`** — interface do stack: `ml_ops_settings`, um `map(object({ project_id, environment_type, ml_engineer_org_group, ml_data_scientist_org_group, data_engineer_org_group }))` — a chave do mapa é livre (sugestão: sigla do projeto/ambiente), normalmente com uma única entrada. `environment_type` é `"nprod"` ou `"prod"` — uma condição genérica de estágio do ambiente (não amarrada a "modelagem"/"inferência" nem a projetos de ML), pra caber em qualquer projeto que use este stack. Agrupado em map(object) em vez de variáveis soltas, seguindo o mesmo padrão usado pelos outros módulos deste repositório (`sa_settings`, `workbench_settings`, etc.) — diferente do mapa de chave fixa do módulo `iam` antigo (`iam_settings["iam"]`, só aceitava uma entrada indexada sempre pela mesma string literal), aqui a chave é escolhida por quem preenche o tfvars. Além disso, `extra_group_role_bindings` para acessos extras específicos de ambiente (aplicado igualmente a toda entrada de `ml_ops_settings`).
- **`locals.tf`** — só `common_labels` hoje (não consumido por nenhum recurso deste stack no momento — mantido para uso futuro).
- **`main.tf`** — `module "iam"` com `for_each = var.ml_ops_settings` (uma instância do módulo `iam_new` por entrada do mapa), passando `ml_ops_profiles` (repassa `environment_type` e os 3 grupos de `each.value`) e `iam_bindings = var.extra_group_role_bindings`.
- **`tfvars/terraform.tfvars`** — `ml_ops_settings` com uma entrada (chave = sigla do projeto). Inclui, comentado, um exemplo de `extra_group_role_bindings` mostrando como reproduzir o acesso que antes vinha fixo no código do módulo `iam` antigo (`G_GCP_RISCFAB_DTSC@corp.caixa.gov.br` → `roles/iam.dataScientist` e `roles/aiplatform.admin`) — está comentado propositalmente; cada ambiente decide explicitamente se ainda precisa desse grant.

Este stack não declara `outputs.tf` no momento — não há nada a expor (`iam_new` não cria mais custom role nem SA; `dataform_service_agent` do módulo não é usado aqui).

**Removido nesta mudança**: `permissions_dataform.tf` e o bloco `custom_roles = { dataform_service_account_role = {...} }` em `main.tf`, que criavam a custom role `dataformServiceAccountBasicRole` — este stack não a vinculava a nenhum membro (comentário no código antigo já registrava "provavelmente consumida por outro stack/processo fora daqui"). Como `iam_new` não cria mais custom roles, essa role deixa de ser criada por este stack; se algum processo externo realmente depende dela, ela precisa ser recriada em outro lugar (ex.: diretamente no stack que a consome, ou via `google_project_iam_custom_role` neste mesmo stack, fora do módulo).

## Por que este stack não cria Service Account

O módulo `iam` (antigo) era a única exceção no repositório onde IAM e criação de identidade viviam juntos — todo módulo de recurso (`airflow_composer/sa.tf`, `cloud_run/sa.tf`, `bq_dataset/sa.tf`, etc.) já cria sua própria SA localmente, e já existe um módulo genérico dedicado a isso (`service_account`) para os casos que não são específicos de um recurso. `iam_new` (e este stack) só concedem permissões — igual a como todo o resto do repositório já trata IAM.

## Pendente antes de ir para produção

- Confirmar os nomes de role sinalizados como não verificados no módulo `iam_new` (`roles/dataform.viewer`, `roles/dataplex.catalogEditor`/`catalogViewer`, `roles/notebooks.viewer`) — ver README daquele módulo.
- Confirmar se algum processo externo depende da custom role `dataformServiceAccountBasicRole` que este stack criava antes (mas não vinculava a nenhum membro) — ela não é mais criada aqui, já que `iam_new` não cria custom roles.
- Publicar `iam_new` e conferir se já está disponível no repositório real consumido pelo pipeline (`GCPprovider/tf-modules-for-gcp`, ver `terraform-workflow/ado-pipeline-extends.yaml`) — hoje `iam_new` só existe em `terraform-code/gcp/iam_new` neste repositório local/espelho.
- Decidir, por ambiente, se o grant do grupo RISCFAB (comentado em `tfvars/terraform.tfvars`) precisa ser reativado via `extra_group_role_bindings`.
- Se este stack for adotado como substituto definitivo do `arch-iam` (e não como uma cópia paralela), migrar o state existente em vez de aplicar do zero — ver seção "Como migrar" no README do `iam_new`.
