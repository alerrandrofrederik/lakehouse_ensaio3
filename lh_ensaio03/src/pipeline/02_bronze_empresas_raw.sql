-- Bronze · base cadastral de empresas (RF-01).
CREATE OR REFRESH STREAMING TABLE bronze.empresas_raw
COMMENT 'Empresas cruas da base cadastral'
AS SELECT
  *,
  _metadata.file_path AS _arquivo,
  current_timestamp() AS _ingerido_em
FROM STREAM read_files(
  '/Volumes/${lead_score.catalog}/landing/raw/empresas/',
  format => 'csv',
  header => true,
  schemaHints => 'cnpj STRING, num_funcionarios INT',
  rescuedDataColumn => '_rescued_data'
);
