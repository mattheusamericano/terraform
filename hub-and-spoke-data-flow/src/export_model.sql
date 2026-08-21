-- Query de Exportacao do Modelo BigQuery ML para o Cloud Storage
EXPORT MODEL `{PROJECT_ID}.models.credit_risk_xgb_v1`
OPTIONS(URI = 'gs://bucket-data-subs-des/models/credpj_risk_xgb_v1');