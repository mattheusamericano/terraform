-- Query de Exportação do Modelo BigQuery ML para o Cloud Storage
EXPORT MODEL `{PROJECT_ID}.__models_dataset__.__model_id__`
OPTIONS(URI = '__train_models_export_uri__');
