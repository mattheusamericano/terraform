-- Query de Treinamento do Modelo BigQuery ML XGBoost para Risco de Crédito PJ
CREATE OR REPLACE MODEL `{PROJECT_ID}.models.credit_risk_xgb_v1`
OPTIONS(
  MODEL_TYPE = 'BOOSTED_TREE_CLASSIFIER',
  INPUT_LABEL_COLS = ['is_default'],
  -- Hiperparâmetros recomendados para árvore de decisão em risco de crédito
  BOOSTER_TYPE = 'GBTREE',
  NUM_PARALLEL_TREE = 1,
  MAX_ITERATIONS = 50,
  LEARN_RATE = 0.1,
  -- Registro automático no Vertex AI Model Registry do Coffer Bank
  MODEL_REGISTRY = 'vertex_ai',
  VERTEX_AI_MODEL_ID = 'credpj_risk_xgb_v1',
  VERTEX_AI_MODEL_VERSION_ALIASES = ['experimental-candidate']
) AS
SELECT
  -- Variável Alvo
  is_default,
  
  -- Features do Analytics Hub (Simuladas/Derivadas)
  bureau_score,
  total_protests,
  sector_market_risk,
  
  -- Features Locais (Sintéticas / Enriquecidas)
  billing_last_12m,
  credit_limit_active,
  leverage_ratio,
  payment_delay_avg_days
FROM
  `{PROJECT_ID}.{DATASET_ID}.credit_features_v1`
WHERE
  -- Divisão determinística de treino (80% da base)
  MOD(CAST(cnpj AS INT64), 10) < 8;
