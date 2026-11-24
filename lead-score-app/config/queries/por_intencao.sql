-- Distribuição dos leads do dia por intenção
SELECT intencao, count(*) AS leads
FROM lh_leadscore_ensaio3.gold.leads_classificados
WHERE data_arquivo = (SELECT max(data_arquivo) FROM lh_leadscore_ensaio3.gold.leads_classificados)
GROUP BY intencao
ORDER BY CASE intencao WHEN 'compra_imediata' THEN 1 WHEN 'avaliando' THEN 2 WHEN 'suporte' THEN 3 ELSE 4 END
