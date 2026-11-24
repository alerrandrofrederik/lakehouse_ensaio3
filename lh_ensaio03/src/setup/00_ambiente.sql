-- Setup do Lead Score: tabela de feedback que o app grava (RF-14). Delta comum, fora do pipeline.
CREATE TABLE IF NOT EXISTS IDENTIFIER(:catalog || '.gold.feedback_contatos') (
  lead_id      STRING    COMMENT 'Lead contatado',
  vendedor     STRING    COMMENT 'Vendedor que fez o contato',
  contatado_em TIMESTAMP COMMENT 'Quando o vendedor marcou como contatado',
  resultado    STRING    COMMENT 'Resultado do contato (ex.: contatado)'
) COMMENT 'Feedback dos vendedores gravado pelo Data App';
