# compute_reservation

Módulo Terraform para criar reservas de capacidade do Compute Engine (`google_compute_reservation`), tipicamente usadas para garantir a disponibilidade de máquinas com GPU em uma zona específica antes de subir workloads (ex.: workbenches ou runtimes de ML que dependem de aceleradores).

## Recursos criados

- `google_compute_reservation.wb_gpu_reservation` — cria uma reserva específica de capacidade (`specific_reservation`) para um tipo de máquina e um tipo/quantidade de GPU, em uma zona determinada, uma para cada chave de `var.compute_reservations_settings`.

## Como usar

```hcl
module "compute_reservation" {
  source = "./gcp/compute_reservation"

  compute_reservations_settings = {
    "reserva-gpu-treino" = {
      project_id           = "meu-projeto-gcp"
      region               = "us-central1"
      zone                 = "a"
      sigla                = "rsv"
      count_rv             = 2
      rv_machine_type      = "a2-highgpu-1g"
      rv_accelerator_type  = "nvidia-tesla-a100"
      rv_accelerator_count = 1
      labels = {
        time = "data-science"
      }
    }
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Default | Obrigatório |
|------|-----------|------|---------|:-----------:|
| `compute_reservations_settings` | Mapa de reservas a serem criadas. `project_id` é o projeto onde a reserva é provisionada, `region`/`zone` compõem a zona final (`${region}-${zone}`), `sigla` um sufixo de nomenclatura, `count_rv` a quantidade de instâncias reservadas, `rv_machine_type` o tipo de máquina reservado, `rv_accelerator_type`/`rv_accelerator_count` (opcionais) o tipo e quantidade de GPU por instância, e `labels` rótulos livres associados à configuração (não usados diretamente no recurso). | `map(object({ project_id = string, region = string, zone = string, sigla = string, count_rv = number, rv_machine_type = optional(string), rv_accelerator_type = optional(string), rv_accelerator_count = optional(number), labels = map(any) }))` | — | Sim |

## Outputs

Este módulo não define outputs (o arquivo `outputs.tf` existe, mas está vazio).

## Observações

- O nome da reserva segue o padrão `${chave}-${sigla}-${terraform.workspace}` e a zona final é montada concatenando `region` e `zone` (ex.: `region = "us-central1"` e `zone = "a"` resultam em `us-central1-a`).
- `specific_reservation_required = true` está fixo no recurso, ou seja, instâncias precisam referenciar explicitamente esta reserva para consumi-la — ela não é usada automaticamente por qualquer instância compatível na zona.
- Todo o módulo é orientado por `for_each` sobre `compute_reservations_settings`, permitindo criar múltiplas reservas em projetos/zonas diferentes numa única aplicação.
- O campo `labels` está declarado na variável mas não é utilizado no recurso `google_compute_reservation`.
