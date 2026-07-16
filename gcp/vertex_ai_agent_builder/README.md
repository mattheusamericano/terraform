# Agent Builder - Endpoint

Módulo Terraform responsável por provisionar **Vertex AI Endpoints** no Google Cloud. Um Endpoint do Vertex AI é o recurso utilizado para hospedar e expor modelos de Machine Learning para inferência online, permitindo que aplicações consumam previsões através de uma interface gerenciada e escalável.

O Endpoint atua como a camada de exposição dos modelos implantados no Vertex AI, oferecendo recursos como isolamento de tráfego, integração com redes privadas, criptografia gerenciada pelo cliente e logging de requisições e respostas.

## Recursos criados

- `google_vertex_ai_endpoint.endpoint` — cria um Endpoint do Vertex AI para cada entrada do mapa `agent_builder_endpoint_settings`, associado a um projeto e região específicos, com suporte a labels e endpoint dedicado.

## Como usar

```hcl
module "agent_builder_endpoint" {
  source = "./gcp/agent_builder_endpoint"

  agent_builder_endpoint_settings = {
    agent_atendimento = {
      project_id    = "meu-projeto-gcp"
      region        = "us-central1"
      sigla         = "atd"

      endpoint_name = "1234567890"
      display_name  = "Agent Atendimento"

      description = "Endpoint utilizado pelo agente de atendimento"

      dedicated_endpoint_enabled = true

      labels = {
        ambiente = "prd"
        squad    = "ia-generativa"
      }
    }

    agent_vendas = {
      project_id    = "meu-projeto-gcp"
      region        = "us-central1"
      sigla         = "vnd"

      endpoint_name = "1234567891"
      display_name  = "Agent Vendas"

      description = "Endpoint utilizado pelo agente comercial"

      labels = {
        ambiente = "dev"
        squad    = "comercial"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `agent_builder_endpoint_settings` | Mapa contendo a configuração dos Endpoints do Vertex AI a serem criados. Cada chave representa um endpoint e é utilizada na composição dos outputs do módulo. | `map(object(...))` | — | Sim |

### Estrutura de `agent_builder_endpoint_settings`

Cada entrada do mapa possui a seguinte estrutura:

| Campo | Tipo | Obrigatório | Default | Descrição |
|---------|------|:-----------:|---------|-----------|
| `project_id` | `string` | Sim | — | Projeto GCP onde o Endpoint será criado. |
| `region` | `string` | Sim | — | Região onde o Endpoint será provisionado. |
| `sigla` | `string` | Sim | — | Identificador utilizado para padronização dos recursos. |
| `endpoint_name` | `string` | Sim | — | Nome único do Endpoint no Vertex AI. |
| `display_name` | `string` | Sim | — | Nome amigável exibido no Console do Google Cloud. |
| `description` | `string` | Não | `null` | Descrição do Endpoint. |
| `dedicated_endpoint_enabled` | `bool` | Não | `false` | Habilita um endpoint dedicado para isolamento de tráfego e maior previsibilidade. |
| `labels` | `map(string)` | Não | `{}` | Labels aplicadas ao Endpoint. |

## Outputs

| Nome | Descrição |
|------|-----------|
| `ids` | IDs dos Endpoints criados, indexados pela chave do mapa `agent_builder_endpoint_settings`. |
| `names` | Nomes dos Endpoints criados, indexados pela chave do mapa. |

## Observações

- O módulo cria apenas o Endpoint do Vertex AI. O deploy de modelos ou agentes dentro do endpoint deve ser realizado separadamente.
- O recurso é criado utilizando `for_each` sobre `agent_builder_endpoint_settings`, portanto cada chave do mapa deve ser única e estável entre execuções (evita recriações desnecessárias dos recursos).
- A API `aiplatform.googleapis.com` é habilitada automaticamente pelo módulo através do recurso `google_project_service.vertex_ai`.
- O atributo `display_name` é utilizado como nome amigável do Endpoint no Console do Google Cloud.
- O atributo `endpoint_name` corresponde ao identificador do Endpoint utilizado pelo Vertex AI.
- Quando `dedicated_endpoint_enabled` estiver configurado como `true`, o Endpoint será exposto por meio de DNS dedicado, fornecendo isolamento de tráfego em relação a outros clientes do serviço.
- As labels definidas em `labels` são aplicadas diretamente ao recurso criado e podem ser utilizadas para organização, governança e controle de custos.
- O output `names` pode ser utilizado por módulos dependentes que necessitem referenciar os Endpoints provisionados.
- Recomenda-se utilizar regiões suportadas pelo Vertex AI e garantir a existência das permissões necessárias para criação e gerenciamento de Endpoints no projeto informado.