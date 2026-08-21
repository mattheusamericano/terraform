-- Query de Avaliação do Modelo BigQuery ML — mesma tabela/colunas de
-- train_model.sql, troque junto se adaptar o schema.
SELECT
  *
FROM
  ML.EVALUATE(
    MODEL `{PROJECT_ID}.__models_dataset__.__model_id__`,
    (
      SELECT
        is_default,
        bureau_score,
        total_protests,
        sector_market_risk,
        billing_last_12m,
        credit_limit_active,
        leverage_ratio,
        payment_delay_avg_days
      FROM
        `{PROJECT_ID}.{DATASET_ID}.credit_features_v1`
      WHERE
        -- Divisão determinística de teste (20% da base)
        MOD(CAST(cnpj AS INT64), 10) >= 8
    )
  );
