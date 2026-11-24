-- Bronze · histórico de oportunidades exportado do CRM (RF-01).
CREATE OR REFRESH STREAMING TABLE bronze.oportunidades_raw
COMMENT 'Oportunidades cruas do CRM'
AS SELECT
  *,
  _metadata.file_path AS _arquivo,
  current_timestamp() AS _ingerido_em
FROM STREAM read_files(
  '/Volumes/${lead_score.catalog}/landing/raw/historico/',
  format => 'csv',
  header => true,
  schemaHints => 'oportunidade_id STRING, cnpj STRING, produto STRING, status STRING, valor DOUBLE, data DATE',
  rescuedDataColumn => '_rescued_data'
);
