# arch-iam_new

Stack de arquitetura equivalente ao [`arch-iam`](../../arch-iam/stacks), reescrito para consumir o módulo [`iam_new`](../../../terraform-code/gcp/iam_new) em vez do `iam`. Mesmo resultado funcional (mesmas Service Accounts, mesmas custom roles, mesmas roles concedidas por padrão), mas toda a configuração de "quem recebe o quê" fica centralizada e explícita neste stack, sem nada hardcoded dentro do módulo — ver o [README do `iam_new`](../../../terraform-code/gcp/iam_new/README.md) para o racional completo da mudança.

## Organização dos arquivos

- **`backend.tf`** / **`providers.tf`** — iguais ao `arch-iam`, usam os mesmos tokens `__project_id__`/`__region__`/`__state-bucket__`/`__backend-prefix__` substituídos pelo pipeline.
- **`variables.tf`** — interface do stack. `project_id` substitui o antigo `iam_settings` (mapa com chave fixa `"iam"`, que não trazia benefício algum). `sa_settings` não exige mais `project_id` por entrada. Nova variável `extra_group_role_bindings` para acessos extras específicos de ambiente.
- **`permissions_dataform.tf`**, **`permissions_ml_viewer.tf`**, **`permissions_ml_engineer.tf`**, **`permissions_data_engineer.tf`**, **`permissions_ml_data_scientist.tf`** — as listas de permissões das custom roles, uma por arquivo (antes, todas concatenadas em um único `locals.tf` de ~2100 linhas). Conteúdo idêntico ao `arch-iam`, só reorganizado; `permissions_ml_data_scientis` foi renomeado para `permissions_ml_data_scientist` (corrigindo o typo).
- **`locals.tf`** — `common_labels` (mantido igual, embora hoje não seja consumido por nenhum recurso deste módulo — ver observação abaixo), os mapas de roles das SAs internas (`permissions_sa_global`, `permissions_sa_composer`, `permissions_sa_pontuais`) e `group_role_bindings`, que monta os grants dos 3 grupos organizacionais dinamicamente (só inclui as roles de um grupo se a variável correspondente não for `null`).
- **`main.tf`** — chamada do módulo `iam_new`, montando `custom_roles`, `sa_role_bindings` e `iam_bindings` a partir dos locals acima.
- **`outputs.tf`** — **novo**: expõe `service_account_emails` e `custom_role_ids`. O `arch-iam` original não expunha nada (nenhum stack `arch-*` neste repo expõe outputs hoje); adicionado aqui para permitir que outros stacks consumam esses valores via remote state sem precisar reimplementar a lógica.
- **`tfvars/terraform.tfvars`** — mesmos SAs e grupos do `arch-iam`. Inclui, comentado, um exemplo de `extra_group_role_bindings` mostrando como reproduzir o acesso que antes vinha fixo no código (`G_GCP_RISCFAB_DTSC@corp.caixa.gov.br` → `roles/iam.dataScientist` e `roles/aiplatform.admin`) — está comentado propositalmente; cada ambiente decide explicitamente se ainda precisa desse grant.

## O que é funcionalmente idêntico ao `arch-iam`

Todas as roles concedidas hoje (inclusive as bem amplas, tipo `roles/storage.admin` e `roles/bigquery.admin` em nível de projeto) permanecem as mesmas. Esta reescrita não reduz escopo de permissão nenhum — apenas muda *como* isso é declarado e concedido (aditivo por padrão em vez de misturar aditivo/autoritativo, sem dado de negócio hardcoded no módulo). Reduzir o escopo em si é um passo separado, que exige validar com os times donos de cada perfil o que realmente é usado — ver "Próximos passos sugeridos" no README do `iam_new`.

## Validado localmente

`terraform validate` e um `terraform plan` local (com valores fictícios no lugar dos tokens `__...__` e sem backend remoto) rodaram sem erros: 56 recursos previstos para criação (9 SAs, 5 custom roles, 18 grants para SAs internas, 24 grants aditivos para os grupos organizacionais), 0 erros de interpolação/tipo.

## Pendente antes de ir para produção

- Publicar o módulo `iam_new` no repositório real consumido pelo pipeline (`GCPprovider/tf-modules-for-gcp`, ver `terraform-workflow/ado-pipeline-extends.yaml`) — hoje ele só existe em `terraform-code/gcp/iam_new` neste repositório local/espelho.
- Decidir, por ambiente, se o grant do grupo RISCFAB (comentado em `tfvars/terraform.tfvars`) precisa ser reativado via `extra_group_role_bindings`.
- Se este stack for adotado como substituto definitivo do `arch-iam` (e não como uma cópia paralela), migrar o state existente em vez de aplicar do zero — ver seção "Como migrar" no README do `iam_new`.
