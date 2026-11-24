-- @param v STRING = 0
-- Funil do dia: recebidos → classificados → na fila → contatados
WITH dia AS (SELECT max(data_arquivo) AS d FROM lh_leadscore_ensaio3.gold.leads_classificados)
SELECT
  (SELECT count(*) FROM lh_leadscore_ensaio3.bronze.leads_raw
     WHERE to_date(regexp_extract(_arquivo, '[0-9]{4}-[0-9]{2}-[0-9]{2}', 0)) = (SELECT d FROM dia)) AS recebidos,
  (SELECT count(*) FROM lh_leadscore_ensaio3.gold.leads_classificados WHERE data_arquivo = (SELECT d FROM dia)) AS classificados,
  (SELECT count(*) FROM lh_leadscore_ensaio3.gold.fila_do_dia) AS na_fila,
  (SELECT count(DISTINCT f.lead_id) FROM lh_leadscore_ensaio3.gold.fila_do_dia f JOIN lh_leadscore_ensaio3.gold.feedback_contatos c ON f.lead_id = c.lead_id) AS contatados,
  (SELECT count(*) FROM lh_leadscore_ensaio3.gold.leads_classificados WHERE intencao = 'compra_imediata' AND data_arquivo = (SELECT d FROM dia)) AS compra_imediata,
  (SELECT count(*) FROM lh_leadscore_ensaio3.gold.leads_classificados c LEFT ANTI JOIN lh_leadscore_ensaio3.gold.fila_do_dia f ON c.lead_id = f.lead_id
     WHERE c.intencao = 'compra_imediata' AND c.data_arquivo = (SELECT d FROM dia)) AS compra_fora_da_fila,
  (SELECT cast(max(d) AS STRING) FROM dia) AS data,
  :v AS versao
