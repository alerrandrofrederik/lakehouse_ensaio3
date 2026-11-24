-- Gold · todos os leads com IA, Lead Score explicável, motivo e próximo passo (RF-09, RF-10, RF-12).
-- lead_score = 0,50 × intenção + 0,25 × perfil + 0,15 × sinais + 0,10 × recência (PRD 2.7)
CREATE OR REFRESH MATERIALIZED VIEW gold.leads_classificados (
  CONSTRAINT score_0_100        EXPECT (lead_score BETWEEN 0 AND 100),
  CONSTRAINT intencao_conhecida EXPECT (intencao IN ('compra_imediata', 'avaliando', 'suporte', 'spam'))
)
COMMENT 'Todos os leads do dia classificados pela IA, com Lead Score de 0 a 100 e os 4 componentes'
AS WITH base AS (
  SELECT
    l.lead_id, l.nome, l.email, l.email_norm, l.telefone, l.cnpj_norm AS cnpj, l.cnpj_valido,
    l.empresa, l.canal, l.campanha, l.porte, l.segmento, l.uf, l.ja_cliente, l.produtos_contratados,
    l.mensagem, l.recebido_em, l.data_arquivo,
    coalesce(ia.intencao, 'spam') AS intencao,
    nullif(trim(ia.produto), '') AS produto,
    ia.qtd_licencas,
    nullif(trim(ia.prazo), '') AS prazo,
    coalesce(ia.orcamento_aprovado, false) AS orcamento_aprovado,
    nullif(trim(ia.cargo), '') AS cargo,
    nullif(trim(ia.concorrente_citado), '') AS concorrente_citado,
    ia.versao_ia
  FROM silver.leads_enriquecidos l
  LEFT JOIN gold.leads_ia ia ON l.lead_id = ia.lead_id
),
componentes AS (
  SELECT
    *,
    CASE intencao WHEN 'compra_imediata' THEN 100 WHEN 'avaliando' THEN 40 ELSE 0 END AS c_intencao,
    least(100,
      CASE porte WHEN 'grande' THEN 100 WHEN 'médio' THEN 60 WHEN 'medio' THEN 60 WHEN 'pequeno' THEN 30 ELSE 20 END
      + CASE WHEN ja_cliente THEN 20 ELSE 0 END) AS c_perfil,
    least(100,
      CASE WHEN orcamento_aprovado THEN 40 ELSE 0 END
      + CASE WHEN prazo IS NOT NULL THEN 30 ELSE 0 END
      + CASE WHEN qtd_licencas IS NOT NULL THEN 30 ELSE 0 END) AS c_sinais,
    CASE datediff(data_arquivo, to_date(recebido_em))
      WHEN 0 THEN 100 WHEN 1 THEN 50 WHEN 2 THEN 25 ELSE 0 END AS c_recencia
  FROM base
),
pedido AS (
  SELECT
    *,
    CASE
      WHEN qtd_licencas IS NULL AND produto IS NULL AND prazo IS NULL THEN
        CASE WHEN intencao = 'compra_imediata' THEN 'Quer comprar' ELSE 'Avaliando a Atlas' END
      ELSE concat_ws(' ',
        CASE WHEN intencao = 'compra_imediata' THEN 'Pediu' ELSE 'Avaliando' END,
        CASE WHEN qtd_licencas IS NOT NULL THEN concat(qtd_licencas, ' licenças') END,
        CASE WHEN produto IS NOT NULL THEN concat(CASE WHEN qtd_licencas IS NOT NULL THEN 'do ' ELSE '' END, produto) END,
        CASE WHEN prazo IS NOT NULL THEN concat('até ', prazo) END)
    END AS frase_pedido
  FROM componentes
)
SELECT
  lead_id, nome, email, email_norm, telefone, cnpj, cnpj_valido, empresa, canal, campanha,
  porte, segmento, uf, ja_cliente, produtos_contratados, mensagem,
  intencao, produto, qtd_licencas, prazo, orcamento_aprovado, cargo, concorrente_citado,
  CASE WHEN intencao = 'spam' THEN 0
       ELSE cast(round(0.50 * c_intencao + 0.25 * c_perfil + 0.15 * c_sinais + 0.10 * c_recencia) AS INT)
  END AS lead_score,
  named_struct('intencao', c_intencao, 'perfil', c_perfil, 'sinais', c_sinais, 'recencia', c_recencia) AS score_componentes,
  CASE
    WHEN intencao = 'spam' THEN 'Sem relação com compra da Atlas'
    WHEN intencao = 'suporte' THEN concat_ws(' · ', 'Pedido de suporte', CASE WHEN ja_cliente THEN 'já é cliente' END)
    ELSE concat_ws(' · ',
      frase_pedido,
      CASE WHEN orcamento_aprovado THEN 'orçamento aprovado' END,
      CASE WHEN concorrente_citado IS NOT NULL THEN concat('usa ', concorrente_citado) END,
      CASE WHEN porte <> 'desconhecido' THEN concat('empresa ', porte) END,
      CASE WHEN ja_cliente THEN 'já é cliente (cross-sell)' END)
  END AS motivo,
  CASE
    WHEN intencao = 'spam' THEN 'Descartar'
    WHEN intencao = 'suporte' THEN 'Encaminhar ao suporte'
    WHEN intencao = 'compra_imediata' AND orcamento_aprovado THEN 'Ligar hoje e enviar proposta'
    WHEN intencao = 'compra_imediata' THEN 'Ligar hoje e qualificar orçamento e prazo'
    ELSE 'Agendar demonstração'
  END AS proximo_passo,
  intencao IN ('compra_imediata', 'avaliando') AS elegivel_fila,
  recebido_em,
  data_arquivo,
  versao_ia,
  current_timestamp() AS processado_em
FROM pedido;
