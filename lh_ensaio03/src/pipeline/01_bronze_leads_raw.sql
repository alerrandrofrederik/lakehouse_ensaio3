-- Bronze · leads como vieram do CSV (RF-01, RF-02). Auto Loader: cada arquivo é lido uma única vez.
-- Data malformada em recebido_em fica nula e o valor original vai para _rescued_data (CA-02).
CREATE OR REFRESH STREAMING TABLE bronze.leads_raw (
  CONSTRAINT recebido_em_valido EXPECT (recebido_em IS NOT NULL)
)
COMMENT 'Leads crus do formulário/LinkedIn/eventos/Ads, um registro por linha de CSV'
AS SELECT
  *,
  _metadata.file_path AS _arquivo,
  current_timestamp() AS _ingerido_em
FROM STREAM read_files(
  '/Volumes/${lead_score.catalog}/landing/raw/leads/',
  format => 'csv',
  header => true,
  multiLine => true,
  timestampFormat => 'yyyy-MM-dd HH:mm:ss',
  schemaHints => 'lead_id STRING, telefone STRING, cnpj STRING, campanha STRING, mensagem STRING, recebido_em TIMESTAMP',
  rescuedDataColumn => '_rescued_data'
);
