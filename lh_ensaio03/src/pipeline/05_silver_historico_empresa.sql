-- Silver · histórico comercial agregado por empresa (RF-05): ganhas e ja_cliente.
CREATE OR REFRESH MATERIALIZED VIEW silver.historico_empresa
COMMENT 'Histórico de oportunidades agregado por CNPJ'
AS SELECT
  regexp_replace(cnpj, '[^0-9]', '') AS cnpj_norm,
  count(*) AS oportunidades,
  count_if(lower(status) = 'ganha') AS oportunidades_ganhas,
  count_if(lower(status) = 'perdida') AS oportunidades_perdidas,
  count_if(lower(status) = 'aberta') AS oportunidades_abertas,
  count_if(lower(status) = 'ganha') > 0 AS ja_cliente,
  array_sort(collect_set(CASE WHEN lower(status) = 'ganha' THEN produto END)) AS produtos_contratados,
  sum(CASE WHEN lower(status) = 'ganha' THEN valor ELSE 0 END) AS valor_ganho
FROM bronze.oportunidades_raw
GROUP BY regexp_replace(cnpj, '[^0-9]', '');
