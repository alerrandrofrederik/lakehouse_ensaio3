-- Lead Score · validação dos critérios de aceite (PRD 3.1). Uma linha por CA, coluna ok = ✅/❌.
WITH
gab AS (
  SELECT * FROM read_files('/Volumes/lh_leadscore_ensaio3/landing/gabarito/intencao.csv', format => 'csv', header => true)
),
acerto AS (
  SELECT g.lead_id, g.pegadinha, g.intencao_esperada, ia.intencao, g.intencao_esperada = ia.intencao AS certo
  FROM gab g JOIN lh_leadscore_ensaio3.gold.leads_ia ia ON g.lead_id = ia.lead_id
),
heroi AS (
  SELECT * FROM lh_leadscore_ensaio3.gold.leads_classificados WHERE lead_id = 'L20261123-0089'
),
fila AS (SELECT * FROM lh_leadscore_ensaio3.gold.fila_do_dia),
cls AS (SELECT * FROM lh_leadscore_ensaio3.gold.leads_classificados),
checks AS (
  SELECT 1 AS n, 'CA-01 linhas na Bronze' AS criterio, '100' AS esperado,
         cast((SELECT count(*) FROM lh_leadscore_ensaio3.bronze.leads_raw) AS STRING) AS obtido
  UNION ALL SELECT 2, 'CA-02 datas em _rescued_data', '2',
         cast((SELECT count(*) FROM lh_leadscore_ensaio3.bronze.leads_raw WHERE _rescued_data IS NOT NULL) AS STRING)
  UNION ALL SELECT 3, 'CA-03 leads únicos na Silver', '96',
         cast((SELECT count(*) FROM lh_leadscore_ensaio3.silver.leads) AS STRING)
  UNION ALL SELECT 4, 'CA-03 e-mails duplicados', '0',
         cast((SELECT count(*) - count(DISTINCT email_norm) FROM lh_leadscore_ensaio3.silver.leads) AS STRING)
  UNION ALL SELECT 5, 'CA-03 CNPJs inválidos', '2',
         cast((SELECT count(*) FROM lh_leadscore_ensaio3.silver.leads WHERE cnpj_norm IS NOT NULL AND NOT cnpj_valido) AS STRING)
  UNION ALL SELECT 6, 'CA-04 reenvio que evolui sobrevive', 'L20261123-0064',
         (SELECT max(lead_id) FROM lh_leadscore_ensaio3.silver.leads WHERE email_norm = 'yasmin.costa@bandeirantes.com.br')
  UNION ALL SELECT 7, 'CA-05 acurácia ai_classify (%)', '>= 85',
         cast((SELECT round(100 * avg(CASE WHEN certo THEN 1 ELSE 0 END), 1) FROM acerto) AS STRING)
  UNION ALL SELECT 8, 'CA-06 pegadinhas corretas', '>= 4 de 5',
         cast((SELECT count_if(certo) FROM acerto WHERE pegadinha IS NOT NULL) AS STRING)
  UNION ALL SELECT 9, 'CA-07 entidades da mensagem herói', 'Atlas Gestão|200|dezembro|true|Diretor Financeiro|OmniERP',
         (SELECT concat_ws('|', produto, cast(qtd_licencas AS STRING), prazo, cast(orcamento_aprovado AS STRING), cargo, concorrente_citado) FROM heroi)
  UNION ALL SELECT 10, 'CA-08 spam/suporte na fila', '0',
         cast((SELECT count_if(intencao IN ('spam', 'suporte')) FROM fila) AS STRING)
  UNION ALL SELECT 11, 'CA-09 leads na fila', '20',
         cast((SELECT count(*) FROM fila) AS STRING)
  UNION ALL SELECT 12, 'CA-09 leads por vendedor', '5 cada',
         (SELECT CASE WHEN min(c) = 5 AND max(c) = 5 AND count(*) = 4 THEN '5 cada' ELSE concat(min(c), '..', max(c)) END
            FROM (SELECT vendedor, count(*) AS c FROM fila GROUP BY vendedor))
  UNION ALL SELECT 13, 'CA-09 posição do herói', '1',
         cast((SELECT posicao FROM fila WHERE lead_id = 'L20261123-0089') AS STRING)
  UNION ALL SELECT 14, 'CA-09 fila com 4 componentes', '20',
         cast((SELECT count(*) FROM fila WHERE score_componentes.intencao IS NOT NULL AND score_componentes.perfil IS NOT NULL
                 AND score_componentes.sinais IS NOT NULL AND score_componentes.recencia IS NOT NULL) AS STRING)
  UNION ALL SELECT 15, 'Agente: compra imediata hoje', '26',
         cast((SELECT count(*) FROM cls WHERE intencao = 'compra_imediata') AS STRING)
  UNION ALL SELECT 16, 'Agente: compra imediata fora da fila', '6',
         cast((SELECT count(*) FROM cls c LEFT ANTI JOIN fila f ON c.lead_id = f.lead_id WHERE c.intencao = 'compra_imediata') AS STRING)
)
SELECT n, criterio, esperado, obtido,
  CASE
    WHEN n = 7 THEN CASE WHEN cast(obtido AS DOUBLE) >= 85 THEN '✅' ELSE '❌' END
    WHEN n = 8 THEN CASE WHEN cast(obtido AS INT) >= 4 THEN '✅' ELSE '❌' END
    WHEN obtido = esperado THEN '✅' ELSE '❌'
  END AS ok
FROM checks
ORDER BY n
