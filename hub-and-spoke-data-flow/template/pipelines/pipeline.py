# Copyright 2026 Google LLC.
# SPDX-License-Identifier: Apache-2.0

# ==============================================================================
# 🚀 PIPELINE DE ML UNIFICADO: TREINAMENTO BQML + SERVING VIA SDK (VERTEX AI)
# ==============================================================================
# TEMPLATE — exemplo funcional de ponta a ponta (treino BQML XGBoost + deploy
# com Canary Split num Endpoint privado). Serve como esqueleto: os parâmetros
# de ambiente (projeto, dataset, bucket, SA) já vêm 100% de model-config.yaml,
# então normalmente você só precisa trocar as queries em src/*.sql pelo seu
# conjunto de features real — a lógica deste arquivo (orquestração do
# pipeline, deploy/Canary) tende a se manter igual entre modelos.
#
# Este script compila e submete o pipeline completo de Machine Learning.
# Ele coordena o treino do modelo no BigQuery ML, sua avaliação e, por fim,
# o deploy dinâmico das versões (Champion/Challenger) no Endpoint privado.
# ==============================================================================

import os
import yaml
import json
import argparse
from kfp import dsl
from kfp import compiler
from google.cloud import aiplatform
from google_cloud_pipeline_components.v1.bigquery import BigqueryQueryJobOp

def load_config():
    """Lê o arquivo model-config.yaml para obter parâmetros dinâmicos."""
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    config_path = os.path.join(base_dir, 'model-config.yaml')
    with open(config_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

# 1. Faz o parsing dos argumentos logo no início, antes da definição do pipeline
parser = argparse.ArgumentParser(description="Configura e compila o pipeline de ML completo.")
parser.add_argument('--environment', type=str, choices=['development', 'production'], default='development', help="Ambiente de execução.")
parser.add_argument('--submit', action='store_true', help="Se definido, submete o pipeline para execução após a compilação.")
args, _ = parser.parse_known_args()

# 2. Carrega as configurações globais com base no ambiente selecionado
try:
    config = load_config()
    model_training_config = config.get('model_training', {})
    environments = model_training_config.get('environments', {})
    env_config = environments.get(args.environment, {})

    # Carrega configurações de serving também
    serving_config = config.get('model_serving', {})
    serving_environments = serving_config.get('environments', {})
    # production/development em serving mapeia para o mesmo de treinamento
    serving_env_config = serving_environments.get(args.environment if args.environment == 'production' else 'development', {})
except Exception as e:
    print(f"Erro ao carregar model-config.yaml: {e}. Usando valores padrão.")
    env_config = {}
    model_training_config = {}
    serving_config = {}
    serving_env_config = {}

# Valores abaixo só são usados se model-config.yaml não puder ser lido —
# ajuste-os para os defaults do seu produto (ou preencha via generate.sh).
PROJECT_ID = env_config.get('project_id', "__train_project_id__")
DATASET_ID = env_config.get('dataset_id', "__dataset_id__")
LOCATION = "__region__"
PIPELINE_ROOT = env_config.get('pipeline_root', "__train_pipeline_root__")
SERVICE_ACCOUNT = env_config.get('service_account', "__train_service_account__")

PIPELINE_NAME = model_training_config.get('pipeline_name', "__pipeline_name__")
SOURCE_DIR = model_training_config.get('source_dir', "src")

# Parâmetros dinâmicos de Serving para o compilador
ENDPOINT_NAME = serving_config.get('endpoint_name', '__endpoint_name__')
DEPLOYMENTS = serving_env_config.get('deployments', [])
DEPLOYMENTS_JSON_STR = json.dumps(DEPLOYMENTS)

print(f"=== Ambiente Configurado (Definition Time): {args.environment.upper()} ===")
print(f"PROJECT_ID: {PROJECT_ID}")
print(f"DATASET_ID: {DATASET_ID}")
print(f"ENDPOINT_NAME: {ENDPOINT_NAME}")
print(f"DEPLOYMENTS: {DEPLOYMENTS_JSON_STR}")
print(f"=====================================")

def read_sql_file(file_path: str, project_id: str, dataset_id: str) -> str:
    """Lê o conteúdo de um arquivo SQL local e formata os placeholders."""
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    absolute_path = os.path.join(base_dir, file_path)
    with open(absolute_path, 'r', encoding='utf-8') as f:
        content = f.read()
    return content.format(PROJECT_ID=project_id, DATASET_ID=dataset_id)

# -----------------------------------------------------------------
# 🎯 COMPONENTE CUSTOMIZADO: DEPLOY DE MODELOS VIA VERTEX AI SDK
# -----------------------------------------------------------------
@dsl.component(
    base_image="gcr.io/ml-pipeline/google-cloud-pipeline-components:2.22.0",
    install_kfp_package=False
)
def deploy_models_to_endpoint_step(
    project_id: str,
    region: str,
    endpoint_name: str,
    deployments_json: str,
    run_id: str
):
    from google.cloud import aiplatform
    import json
    import sys

    print(f"=====================================================")
    print(f"INICIANDO STEP DE DEPLOY DE SERVENTIA NA VERTEX AI")
    print(f"=====================================================")

    # Carrega a lista de deploys declarados no YAML
    deployments = json.loads(deployments_json)
    if not deployments:
        print("Nenhum deployment de serving foi declarado no model-config.yaml. Pulando etapa de deploy.")
        return

    aiplatform.init(project=project_id, location=region)

    # Determina a sigla do ambiente (publisher/subscriber) compatível com a
    # convenção de nomenclatura da Landing Zone hub-and-spoke — ajuste esta
    # heurística se o seu projeto não seguir o padrão "-poc"/"prd".
    env_sigla = "publisher" if project_id.endswith("publisher-poc") or "prd" in project_id else "subscriber"
    endpoint_full_name = f"{endpoint_name}-{env_sigla}"

    print(f"Procurando endpoint estavel: '{endpoint_full_name}'...")
    try:
        # Tenta instanciar diretamente pelo ID (comum para recursos provisionados via IaC)
        endpoint = aiplatform.Endpoint(endpoint_name=endpoint_full_name)
        print(f"Endpoint estavel localizado diretamente pelo ID: {endpoint.resource_name}")
    except Exception as e:
        print(f"Aviso: Nao foi possivel carregar o endpoint '{endpoint_full_name}' diretamente ({e}). Tentando listar por display_name...")
        endpoints = aiplatform.Endpoint.list(filter=f'display_name="{endpoint_full_name}"')
        if not endpoints:
            print(f"Erro Critico: Endpoint '{endpoint_full_name}' nao foi encontrado no projeto {project_id}.")
            print("Verifique se o repositorio de IaC (-iac) provisionou o endpoint com sucesso.")
            sys.exit(1)
        endpoint = endpoints[0]
        print(f"Endpoint estavel localizado por display_name: {endpoint.resource_name}")

    print(f"Deploys declarados para execucao: {deployments}")

    # Lista os modelos atualmente deployados no endpoint
    deployed_models = endpoint.list_models()
    deployed_models_dict = {dm.model.split('/')[-1]: dm.id for dm in deployed_models}
    print(f"Modelos atualmente ativos no endpoint: {deployed_models_dict}")

    traffic_split_target = {}

    for dep in deployments:
        model_id = dep["model_id"]
        version_id = dep["version_id"]
        traffic_percent = dep["traffic_percentage"]
        machine_type = dep["machine_type"]
        min_replica = dep["min_replica_count"]
        max_replica = dep["max_replica_count"]

        # MLOps de Producao: Para rodar em Endpoint Privado, registramos e usamos o modelo como custom-trained!
        custom_model_id = f"{model_id}_custom_serving"
        custom_model_display_name = f"{model_id}-custom-serving"
        gcs_model_uri = f"gs://bkt-{project_id}-storage/models/{model_id}"

        print(f"Carregando/Registrando modelo custom-trained para Endpoint Privado: {custom_model_id} (GCS: {gcs_model_uri})")
        try:
            model = aiplatform.Model(model_name=f"projects/{project_id}/locations/{region}/models/{custom_model_id}")
            print(f"Modelo custom-trained '{custom_model_id}' ja existe: {model.resource_name}")
        except Exception:
            print(f"Modelo custom-trained '{custom_model_id}' nao encontrado. Registrando no Model Registry...")
            try:
                model = aiplatform.Model.upload(
                    display_name=custom_model_display_name,
                    model_id=custom_model_id,
                    artifact_uri=gcs_model_uri,
                    serving_container_image_uri="us-docker.pkg.dev/vertex-ai/prediction/xgboost-cpu.1-6:latest",
                    sync=True
                )
                print(f"Modelo custom-trained registrado com sucesso: {model.resource_name}")
            except Exception as e:
                print(f"Aviso: Nao foi possivel registrar o modelo custom-trained '{custom_model_id}' ({e}). Pulando este deployment.")
                continue

        # Se o modelo ja esta deployado no endpoint, reutilizamos o ID
        if custom_model_id in deployed_models_dict:
            deployed_model_id = deployed_models_dict[custom_model_id]
            print(f"Modelo '{custom_model_id}' ja esta deployado (ID: {deployed_model_id}).")
            traffic_split_target[deployed_model_id] = traffic_percent
        else:
            # Caso contrario, inicia o deploy fisico do modelo custom-trained
            print(f"Iniciando deploy fisico do modelo '{custom_model_id}'...")
            try:
                endpoint.deploy(
                    model=model,
                    deployed_model_display_name=f"{custom_model_id}-active",
                    machine_type=machine_type,
                    min_replica_count=min_replica,
                    max_replica_count=max_replica,
                    traffic_percentage=traffic_percent
                )
                print(f"Modelo '{custom_model_id}' deployado com sucesso!")

                # Sincroniza o ID recem-criado
                for dm in endpoint.list_models():
                    if dm.model.split('/')[-1] == custom_model_id:
                        traffic_split_target[dm.id] = traffic_percent
            except Exception as e:
                print(f"Erro ao fazer deploy do modelo '{custom_model_id}': {e}")
                sys.exit(1)

    # Sincroniza pesos de trafego de forma atomica
    if traffic_split_target:
        # Normaliza os pesos para que a soma seja exatamente 100%
        total_traffic = sum(traffic_split_target.values())
        if total_traffic > 0:
            print(f"Normalizando pesos de trafego (soma atual: {total_traffic}%)...")
            traffic_split_target = {mid: int(pct * 100 / total_traffic) for mid, pct in traffic_split_target.items()}
            # Garante soma exata de 100% compensando arredondamentos
            keys = list(traffic_split_target.keys())
            traffic_split_target[keys[0]] += 100 - sum(traffic_split_target.values())

        print(f"Sincronizando pesos do Canary Split no Endpoint: {traffic_split_target}")
        try:
            endpoint.update(traffic_split=traffic_split_target)
            print("Divisao de trafego atualizada com sucesso!")
        except Exception as e:
            # Em endpoints privados na Landing Zone, divisao de trafego por API nao e suportada devido ao peering VPC.
            # Capturamos esse erro especifico para nao quebrar a esteira de MLOps de forma desnecessaria.
            if "traffic splitting is not supported" in str(e).lower():
                print(f"Aviso: Divisao de trafego explicita nao e suportada para Endpoint Privado ({e}). Prosseguindo, ja que o modelo foi deployado fisicamente com sucesso!")
            else:
                print(f"Erro ao atualizar divisao de trafego: {e}")
                sys.exit(1)

    print("=====================================================")
    print("ETAPA DE SERVING EXECUTADA COM SUCESSO!")
    print("=====================================================")

# -----------------------------------------------------------------
# 🏗️ DEFINIÇÃO DO PIPELINE DE MLOPS UNIFICADO
# -----------------------------------------------------------------
@dsl.pipeline(
    name=PIPELINE_NAME,
    description='Pipeline de MLOps completo (Treinamento BQML XGBoost + Serving via SDK) orquestrado via Vertex AI Pipelines.'
)
def mlops_pipeline(
    project_id: str,
    dataset_id: str,
    location: str = "__region__",
    endpoint_name: str = ENDPOINT_NAME,
    deployments_json: str = DEPLOYMENTS_JSON_STR,
    run_id: str = ""
):
    # Carrega as queries SQL interpolando os placeholders com as variáveis de compilação
    train_query = read_sql_file(f'{SOURCE_DIR}/train_model.sql', PROJECT_ID, DATASET_ID)
    evaluate_query = read_sql_file(f'{SOURCE_DIR}/evaluate_model.sql', PROJECT_ID, DATASET_ID)
    export_query = read_sql_file(f'{SOURCE_DIR}/export_model.sql', PROJECT_ID, DATASET_ID)

    # Passo 1: Treinar o modelo BigQuery ML XGBoost
    train_task = BigqueryQueryJobOp(
        project=project_id,
        location=location,
        query=train_query
    ).set_display_name("Treinamento do Modelo BQML XGBoost")

    # Passo 2: Avaliar a performance do modelo treinado
    evaluate_task = BigqueryQueryJobOp(
        project=project_id,
        location=location,
        query=evaluate_query
    ).set_display_name("Avaliacao do Modelo (ML.EVALUATE)").after(train_task)

    # Passo 2b: Exportar o modelo BigQuery ML para o Cloud Storage
    export_task = BigqueryQueryJobOp(
        project=project_id,
        location=location,
        query=export_query
    ).set_display_name("Exportacao do Modelo BQML para GCS").after(evaluate_task)

    # Passo 3: Deploy do Modelo e Canary Split (Vertex AI SDK) - Apenas em Produção (Inferência)
    if args.environment == 'production':
        deploy_task = deploy_models_to_endpoint_step(
            project_id=project_id,
            region=location,
            endpoint_name=endpoint_name,
            deployments_json=deployments_json,
            run_id=run_id
        ).set_display_name("Deploy e Reconciliacao de Serventia (Canary Split)").after(export_task)

if __name__ == '__main__':
    # Caminho do pacote compilado
    pipeline_package_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'pipeline.json')

    # Compila o pipeline
    compiler.Compiler().compile(
        pipeline_func=mlops_pipeline,
        package_path=pipeline_package_path
    )
    print(f"Pipeline compilado com sucesso para '{pipeline_package_path}'!")

    # Se a flag --submit for passada, envia para execução no Vertex AI Pipelines
    if args.submit:
        print("=== Iniciando submissão do pipeline unificado no Vertex AI ===")
        aiplatform.init(project=PROJECT_ID, location=LOCATION)

        job = aiplatform.PipelineJob(
            display_name=f"{PIPELINE_NAME}-run-{args.environment}",
            template_path=pipeline_package_path,
            pipeline_root=PIPELINE_ROOT,
            enable_caching=False,
            parameter_values={
                "project_id": PROJECT_ID,
                "dataset_id": DATASET_ID,
                "location": LOCATION,
                "endpoint_name": ENDPOINT_NAME,
                "deployments_json": DEPLOYMENTS_JSON_STR
            }
        )

        # Submete o job usando a Service Account de IaC/MLOps dedicada
        job.submit(service_account=SERVICE_ACCOUNT)
        print("Pipeline MLOps unificado SUBMETIDO com sucesso para o Vertex AI Pipelines!")
