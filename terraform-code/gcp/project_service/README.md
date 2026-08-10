# project_service

Módulo Terraform simples para **habilitar APIs do Google Cloud** em um projeto (equivalente a `gcloud services enable`). Costuma ser um dos primeiros módulos aplicados em um projeto, já que muitos outros recursos dependem de APIs habilitadas previamente.

## Recursos criados

- `google_project_service.project` — habilita, para cada item da lista `apis_list`, o respectivo serviço/API no projeto `project_id`. Usa `disable_on_destroy = false`, ou seja, destruir o recurso no Terraform não desabilita a API no projeto.

## Como usar

```hcl
module "project_service" {
  source = "./gcp/project_service"

  project_id = "meu-projeto-gcp"

  apis_list = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "cloudkms.googleapis.com",
    "firestore.googleapis.com",
    "dataplex.googleapis.com",
  ]
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `project_id` | Projeto no qual as APIs serão habilitadas. | `string` | — | sim |
| `apis_list` | Lista de APIs (nomes de serviço, ex. `compute.googleapis.com`) a serem habilitadas no projeto. | `list(string)` | `[]` | não |

## Outputs

| Nome | Descrição |
|------|-----------|
| `enabled_apis` | Lista das APIs que foram habilitadas neste projeto. |

## Observações

- O recurso usa `for_each = toset(var.apis_list)`, então a lista de APIs não pode conter duplicatas e a ordem não é relevante para o estado do Terraform.
- `disable_on_destroy = false` significa que remover uma API da lista (ou destruir o módulo) apenas remove o recurso do state do Terraform, **sem desabilitar** a API no projeto real — evita quebrar outros recursos/dependências que ainda usem a API habilitada.
- Se `apis_list` estiver vazia (default), nenhum recurso é criado.
