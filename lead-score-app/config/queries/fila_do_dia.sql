-- @param v STRING = 0
-- Fila do Dia com os componentes do score e o status de contato (v = cache-buster)
SELECT
  f.posicao, f.vendedor, f.lead_id, f.nome, f.email, f.telefone, f.empresa, f.cargo, f.canal, f.campanha,
  f.porte, f.segmento, f.uf, f.ja_cliente, f.intencao, f.lead_score,
  f.score_componentes.intencao AS c_intencao, f.score_componentes.perfil AS c_perfil,
  f.score_componentes.sinais AS c_sinais, f.score_componentes.recencia AS c_recencia,
  f.produto, f.qtd_licencas, f.prazo, f.orcamento_aprovado, f.concorrente_citado,
  f.motivo, f.proximo_passo, f.mensagem, date_format(f.recebido_em, 'HH:mm') AS hora,
  c.contatado_em IS NOT NULL AS contatado, :v AS versao
FROM lh_leadscore_ensaio3.gold.fila_do_dia f
LEFT JOIN (SELECT lead_id, max(contatado_em) AS contatado_em FROM lh_leadscore_ensaio3.gold.feedback_contatos GROUP BY lead_id) c
  ON f.lead_id = c.lead_id
ORDER BY f.posicao
