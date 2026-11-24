-- Silver · leads limpos e deduplicados (RF-03, RF-04, RF-06).
-- E-mail normalizado, CNPJ com 14 dígitos e dígito verificador, dedup pelo e-mail mantendo o mais recente.
CREATE OR REFRESH MATERIALIZED VIEW silver.leads (
  CONSTRAINT lead_id_presente EXPECT (lead_id IS NOT NULL),
  CONSTRAINT email_valido     EXPECT (email_norm RLIKE '^[^@]+@[^@]+[.][^@]+$'),
  CONSTRAINT cnpj_dv_ok       EXPECT (cnpj_norm IS NULL OR cnpj_valido),
  CONSTRAINT recebido_em_ok   EXPECT (recebido_em IS NOT NULL)
)
COMMENT 'Leads limpos, um por e-mail normalizado (mensagem mais recente)'
AS WITH base AS (
  SELECT
    lead_id,
    trim(nome) AS nome,
    email,
    lower(regexp_replace(email, '[[:space:]]', '')) AS email_norm,
    telefone,
    nullif(regexp_replace(cnpj, '[^0-9]', ''), '') AS cnpj_norm,
    lower(trim(canal)) AS canal,
    trim(campanha) AS campanha,
    mensagem,
    recebido_em,
    _rescued_data,
    _arquivo,
    to_date(regexp_extract(_arquivo, '[0-9]{4}-[0-9]{2}-[0-9]{2}', 0)) AS data_arquivo,
    _ingerido_em
  FROM bronze.leads_raw
),
dv AS (
  SELECT
    *,
    CASE
      WHEN cnpj_norm IS NULL OR length(cnpj_norm) <> 14 THEN NULL
      ELSE aggregate(sequence(1, 12), 0, (acc, i) ->
             acc + cast(substr(cnpj_norm, i, 1) AS INT) * element_at(array(5,4,3,2,9,8,7,6,5,4,3,2), i))
    END AS soma1,
    CASE
      WHEN cnpj_norm IS NULL OR length(cnpj_norm) <> 14 THEN NULL
      ELSE aggregate(sequence(1, 13), 0, (acc, i) ->
             acc + cast(substr(cnpj_norm, i, 1) AS INT) * element_at(array(6,5,4,3,2,9,8,7,6,5,4,3,2), i))
    END AS soma2
  FROM base
),
validado AS (
  SELECT
    * EXCEPT (soma1, soma2),
    coalesce(
      cast(substr(cnpj_norm, 13, 1) AS INT) = CASE WHEN soma1 % 11 < 2 THEN 0 ELSE 11 - soma1 % 11 END
      AND cast(substr(cnpj_norm, 14, 1) AS INT) = CASE WHEN soma2 % 11 < 2 THEN 0 ELSE 11 - soma2 % 11 END,
      false
    ) AS cnpj_valido
  FROM dv
)
SELECT * EXCEPT (rn)
FROM (
  SELECT *,
    row_number() OVER (PARTITION BY email_norm ORDER BY recebido_em DESC NULLS LAST, lead_id DESC) AS rn
  FROM validado
)
WHERE rn = 1;
