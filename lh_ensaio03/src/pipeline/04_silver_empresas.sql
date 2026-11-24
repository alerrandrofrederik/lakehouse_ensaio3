-- Silver · empresas com CNPJ normalizado (14 dígitos), uma linha por CNPJ (RF-03).
CREATE OR REFRESH MATERIALIZED VIEW silver.empresas (
  CONSTRAINT cnpj_14_digitos EXPECT (length(cnpj_norm) = 14)
)
COMMENT 'Empresas limpas, uma por CNPJ'
AS SELECT cnpj_norm, razao_social, porte, segmento, num_funcionarios, uf
FROM (
  SELECT
    regexp_replace(cnpj, '[^0-9]', '') AS cnpj_norm,
    trim(razao_social) AS razao_social,
    lower(trim(porte)) AS porte,
    trim(segmento) AS segmento,
    num_funcionarios,
    upper(trim(uf)) AS uf,
    row_number() OVER (PARTITION BY regexp_replace(cnpj, '[^0-9]', '') ORDER BY _ingerido_em DESC) AS rn
  FROM bronze.empresas_raw
)
WHERE rn = 1;
