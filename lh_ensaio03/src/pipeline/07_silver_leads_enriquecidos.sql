-- Silver · lead + empresa (por CNPJ válido) + histórico agregado (RF-05).
CREATE OR REFRESH MATERIALIZED VIEW silver.leads_enriquecidos
COMMENT 'Leads deduplicados unidos ao cadastro da empresa e ao histórico comercial'
AS SELECT
  l.*,
  e.razao_social AS empresa,
  coalesce(e.porte, 'desconhecido') AS porte,
  e.segmento,
  e.uf,
  e.num_funcionarios,
  coalesce(h.ja_cliente, false) AS ja_cliente,
  coalesce(h.oportunidades_ganhas, 0) AS oportunidades_ganhas,
  h.produtos_contratados
FROM silver.leads l
LEFT JOIN silver.empresas e
  ON l.cnpj_valido AND l.cnpj_norm = e.cnpj_norm
LEFT JOIN silver.historico_empresa h
  ON l.cnpj_valido AND l.cnpj_norm = h.cnpj_norm;
