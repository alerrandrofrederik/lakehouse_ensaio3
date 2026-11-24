-- Gold · IA sobre a mensagem (RF-07, RF-08). STREAMING TABLE sobre a Bronze:
-- só linhas novas chamam a IA (CA-12). Mensagem com menos de 5 caracteres vira spam sem IA.
-- ai_extract roda só para compra_imediata e avaliando.
CREATE OR REFRESH STREAMING TABLE gold.leads_ia
COMMENT 'Intenção (ai_classify) e entidades (ai_extract) de cada linha de lead, calculadas uma única vez'
AS WITH classificado AS (
  SELECT
    lead_id,
    _arquivo,
    mensagem,
    CASE
      WHEN length(trim(coalesce(mensagem, ''))) < 5 THEN 'spam'
      ELSE ai_classify(
        mensagem,
        '{
          "compra_imediata": "Quer comprar produtos da Atlas Software: pede preço, proposta, quantidade de licenças, prazo ou reunião comercial",
          "avaliando":       "Quer conhecer os produtos da Atlas, comparar opções ou ver uma demonstração, sem urgência",
          "suporte":         "Já é cliente da Atlas e relata problema, dúvida de uso ou pede ajuda técnica",
          "spam":            "Sem relação com comprar da Atlas: oferta ou propaganda de terceiros (SEO, empréstimo, marketing), teste ou texto sem sentido, mesmo que use palavras como urgente, proposta ou preço"
        }',
        map('version', '2.1')
      ):response[0].value::string
    END AS intencao,
    length(trim(coalesce(mensagem, ''))) >= 5 AS ia_chamada
  FROM STREAM(bronze.leads_raw)
),
extraido AS (
  SELECT
    *,
    CASE WHEN intencao IN ('compra_imediata', 'avaliando') THEN
      ai_extract(
        mensagem,
        '{
          "produto":            {"type": "string",  "description": "Produto Atlas citado"},
          "qtd_licencas":       {"type": "integer", "description": "Quantidade de licenças ou usuários"},
          "prazo":              {"type": "string",  "description": "Prazo ou data desejada, só o mês ou a data, sem preposição (ex.: dezembro)"},
          "orcamento_aprovado": {"type": "boolean", "description": "Mencionou orçamento aprovado"},
          "cargo":              {"type": "string",  "description": "Cargo de quem escreveu"},
          "concorrente_citado": {"type": "string",  "description": "Sistema concorrente de outra empresa que o lead usa ou avalia (nunca um produto Atlas)"}
        }',
        map('version', '2.1')
      )
    END AS entidades_raw
  FROM classificado
)
SELECT
  lead_id,
  _arquivo,
  intencao,
  entidades_raw:response.produto.value::string             AS produto,
  entidades_raw:response.qtd_licencas.value::int           AS qtd_licencas,
  entidades_raw:response.prazo.value::string               AS prazo,
  entidades_raw:response.orcamento_aprovado.value::boolean AS orcamento_aprovado,
  entidades_raw:response.cargo.value::string               AS cargo,
  entidades_raw:response.concorrente_citado.value::string  AS concorrente_citado,
  entidades_raw,
  ia_chamada,
  'ai_classify 2.1 · ai_extract 2.1' AS versao_ia,
  current_timestamp() AS processado_em
FROM extraido;
