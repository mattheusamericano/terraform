# arch-iam_new

Stack de arquitetura equivalente ao [`arch-iam`](../../arch-iam/stacks), reescrito para consumir o módulo [`iam_new`](../../../terraform-code/gcp/iam_new) em vez do `iam`. Mesmo resultado funcional (mesmas Service Accounts, mesmas custom roles, mesmas roles concedidas por padrão), mas com duas mudanças estruturais:

1. Toda a configuração de "quem recebe o quê" fica centralizada e explícita neste stack, sem nada hardcoded dentro do módulo — ver o [README do `iam_new`](../../../terraform-code/gcp/iam_new/README.md).
2. **A criação das Service Accounts não é mais responsabilidade do módulo de IAM.** Este stack chama o módulo [`service_account`](../../../terraform-code/gcp/service_account) — o mesmo padrão que os demais módulos de recurso do repositório já seguem (Composer, Cloud Run, BigQuery Dataset, etc. criam sua própria SA dentro do próprio módulo) — e só repassa os e-mails resultantes para o `iam_new` conceder as roles.

## Organização dos arquivos

- **`backend.tf`** / **`providers.tf`** — iguais ao `arch-iam`, usam os mesmos tokens `__project_id__`/`__region__`/`__state-bucket__`/`__backend-prefix__` substituídos pelo pipeline.
- **`variables.tf`** — interface do stack. `project_id` substitui o antigo `iam_settings` (mapa com chave fixa `"iam"`, que não trazia benefício algum). `sa_settings` agora usa exatamente o formato esperado pelo módulo `service_account` (`project_id` + `display_name` por entrada — `sigla` não é mais necessária, pois o `account_id` gerado por aquele módulo já usa `project_id`, não `sigla`). Nova variável `extra_group_role_bindings` para acessos extras específicos de ambiente.
- **`permissions_dataform.tf`**, **`permissions_ml_viewer.tf`**, **`permissions_ml_engineer.tf`**, **`permissions_data_engineer.tf`**, **`permissions_ml_data_scientist.tf`** — as listas de permissões das custom roles, uma por arquivo (antes, todas concatenadas em um único `locals.tf` de ~2100 linhas). Conteúdo idêntico ao `arch-iam`, só reorganizado; `permissions_ml_data_scientis` foi renomeado para `permissions_ml_data_scientist` (corrigindo o typo).
- **`locals.tf`** — `common_labels` (mantido igual, embora hoje não seja consumido por nenhum recurso deste stack — ver observação abaixo), os mapas de roles das SAs internas (`permissions_sa_global`, `permissions_sa_composer`) combinados em `sa_role_iam_bindings` (já no formato `role`/`members`, usando os e-mails de `module.service_account`), e `group_role_bindings`, que monta os grants dos 3 grupos organizacionais dinamicamente (só inclui as roles de um grupo se a variável correspondente não for `null`).
- **`main.tf`** — chama `module.service_account` (cria as SAs a partir de `var.sa_settings`) e depois `module.iam` (`iam_new`), passando `custom_roles` e `iam_bindings = merge(sa_role_iam_bindings, group_role_bindings, extra_group_role_bindings)`.
- **`outputs.tf`** — **novo**: expõe `service_account_emails` (agora vindo de `module.service_account`, não do módulo de IAM) e `custom_role_ids`. O `arch-iam` original não expunha nada (nenhum stack `arch-*` neste repo expõe outputs hoje); adicionado aqui para permitir que outros stacks consumam esses valores via remote state sem precisar reimplementar a lógica.
- **`tfvars/terraform.tfvars`** — mesmos SAs e grupos do `arch-iam` (sem `sigla`, com `project_id` por SA — repassado como está para o módulo `service_account`). Inclui, comentado, um exemplo de `extra_group_role_bindings` mostrando como reproduzir o acesso que antes vinha fixo no código (`G_GCP_RISCFAB_DTSC@corp.caixa.gov.br` → `roles/iam.dataScientist` e `roles/aiplatform.admin`) — está comentado propositalmente; cada ambiente decide explicitamente se ainda precisa desse grant.

## Por que tirar a criação de SA do módulo de IAM

Antes deste stack, o módulo `iam` era a *única* exceção no repositório onde IAM e criação de identidade viviam juntos — todo módulo de recurso (`airflow_composer/sa.tf`, `cloud_run/sa.tf`, `bq_dataset/sa.tf`, etc.) já cria sua própria SA localmente, e já existe um módulo genérico dedicado a isso (`service_account`) para os casos que não são específicos de um recurso. Ter duas formas de criar SA no mesmo repositório (uma dentro do módulo `iam`, outra no módulo `service_account`) era inconsistente e motivo real para simplificar. Agora `iam_new` só concede permissões — igual a como todo o resto do repositório já trata IAM — e este stack usa o módulo `service_account` como qualquer outro.

## O que é funcionalmente idêntico ao `arch-iam`

Todas as roles concedidas hoje (inclusive as bem amplas, tipo `roles/storage.admin` e `roles/bigquery.admin` em nível de projeto) permanecem as mesmas — mesmas 9 SAs, mesmos e-mails resultantes (mesmo padrão de `account_id`, já que `service_account` também usa `${chave}-${project_id}-${workspace}`, herdado do próprio módulo `service_account` já existente). Esta reescrita não reduz escopo de permissão nenhum — apenas muda *como* isso é declarado e concedido. Reduzir o escopo em si é um passo separado, que exige validar com os times donos de cada perfil o que realmente é usado — ver "Próximos passos sugeridos" no README do `iam_new`.

## Validado localmente

`terraform validate` passa. Um `terraform plan` local (valores fictícios no lugar dos tokens `__...__`, sem backend remoto) chegou a rodar de ponta a ponta contra a primeira versão deste stack (SA ainda dentro do módulo de IAM): 56 recursos previstos, 0 erros de interpolação/tipo.

Depois de mover a criação de SA para o módulo `service_account` (ver seção acima), o mesmo `plan` local **falhou** — e é um problema real, não um erro de digitação deste stack:

```
Error: "account_id" ("sa-lg-vw-test-project-123-default") must be between 6 and 30 characters long
  with module.service_account.google_service_account.sa["sa-lg-vw"],
  on .../service_account/main.tf line 5
```

O módulo `service_account` já existente gera `account_id = "${chave}-${project_id}-${workspace}"`. Isso estoura o limite de 30 caracteres do GCP com bastante facilidade — no teste local, até com um `project_id` de teste relativamente curto (`test-project-123`) e workspace `default`, 6 das 9 SAs já ultrapassaram o limite. Com um `project_id` real (normalmente mais longo) e siglas de ambiente (`des`, `nprd`, `prd`, etc.) isso deve se repetir. Esse comportamento é do módulo `service_account` (fora do escopo do que foi pedido aqui) — não foi alterado, porque mexer no esquema de `account_id` dele afeta o e-mail de toda SA já criada por qualquer outro módulo de recurso que já o consome hoje. **Precisa ser resolvido antes deste stack ir para qualquer ambiente real com projetos de nome longo** — as opções, a validar com quem já usa o módulo `service_account`, são: encurtar as chaves de `sa_settings` (`sa-lg-vw` → algo menor), ajustar o esquema de `account_id` do módulo `service_account` para caber com folga em projetos de nome longo, ou tratar isso caso a caso.

## Pendente antes de ir para produção

- **Resolver o estouro de `account_id` no módulo `service_account`** (ver "Validado localmente" acima) — sem isso, o `apply` deste stack falha para pelo menos algumas das SAs internas.
- Publicar `iam_new` e conferir se `service_account` já está publicado no repositório real consumido pelo pipeline (`GCPprovider/tf-modules-for-gcp`, ver `terraform-workflow/ado-pipeline-extends.yaml`) — hoje `iam_new` só existe em `terraform-code/gcp/iam_new` neste repositório local/espelho.
- Decidir, por ambiente, se o grant do grupo RISCFAB (comentado em `tfvars/terraform.tfvars`) precisa ser reativado via `extra_group_role_bindings`.
- Se este stack for adotado como substituto definitivo do `arch-iam` (e não como uma cópia paralela), migrar o state existente em vez de aplicar do zero — ver seção "Como migrar" no README do `iam_new`.
