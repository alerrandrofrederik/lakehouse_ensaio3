-- Gold · Fila do Dia: os 20 leads de maior score do dia, 5 por vendedor (RF-11).
-- "Dia" = max(data_arquivo). Spam e suporte ficam fora (CA-08). O desempate põe o herói em #1.
CREATE OR REFRESH MATERIALIZED VIEW gold.fila_do_dia (
  CONSTRAINT sem_spam_suporte EXPECT (intencao IN ('compra_imediata', 'avaliando'))
)
COMMENT 'Fila do Dia: 20 leads priorizados, distribuídos em round-robin entre os 4 vendedores'
AS WITH dia AS (
  SELECT max(data_arquivo) AS dia FROM gold.leads_classificados
),
ranqueado AS (
  SELECT
    d.dia,
    row_number() OVER (
      ORDER BY c.lead_score DESC, c.score_componentes.sinais DESC, c.score_componentes.perfil DESC,
               c.qtd_licencas DESC NULLS LAST, c.recebido_em ASC, c.lead_id
    ) AS pos,
    c.*
  FROM gold.leads_classificados c
  JOIN dia d ON c.data_arquivo = d.dia
  WHERE c.elegivel_fila
)
SELECT
  dia AS data,
  cast(pos AS INT) AS posicao,
  element_at(array('Ana Ribeiro', 'Bruno Carvalho', 'Carla Mendes', 'Diego Rocha'), cast((pos - 1) % 4 + 1 AS INT)) AS vendedor,
  * EXCEPT (dia, pos)
FROM ranqueado
WHERE pos <= 20;
