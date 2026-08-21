-- Query de Avaliação do Modelo BigQuery ML XGBoost para Risco de Crédito PJ
SELECT
  *
FROM
  ML.EVALUATE(
    MODEL `{PROJECT_ID}.models.credit_risk_xgb_v1`,
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
