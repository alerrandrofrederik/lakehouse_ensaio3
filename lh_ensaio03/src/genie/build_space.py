"""Cria o Genie Space "Lead Score · Agente Comercial" sobre as 3 tabelas Gold (RF-16).

Uso:  py -I lh_ensaio03/src/genie/build_space.py      → imprime o space_id
"""
import json
import os
import subprocess
import sys
import tempfile
import uuid

PROFILE = os.environ.get("LS_PROFILE", "lead_score")
WAREHOUSE = os.environ.get("LS_WAREHOUSE", "a50e6a998ebe9440")
CAT = os.environ.get("LS_CATALOG", "lh_leadscore_ensaio3")
TITULO = "Lead Score · Agente Comercial"

G = f"{CAT}.gold"

INSTRUCOES = f"""Você é o agente comercial da Atlas Software. Responda sempre em português, de forma curta.
- "hoje" ou "do dia" = data_arquivo = (SELECT max(data_arquivo) FROM {G}.leads_classificados). Nunca use current_date().
- Intenções possíveis em intencao: compra_imediata, avaliando, suporte, spam.
- "fila" ou "fila do dia" = tabela {G}.fila_do_dia (20 leads, 5 por vendedor, coluna posicao de 1 a 20).
- "fora da fila" = leads de {G}.leads_classificados com intencao = 'compra_imediata' LEFT ANTI JOIN {G}.fila_do_dia por lead_id.
- "contatado" = existe linha em {G}.feedback_contatos para o lead_id. "minha fila" = fila do vendedor citado; sem vendedor, considere a fila inteira.
- Canais (canal): site, linkedin, evento, indicacao, google_ads.
- Concorrente citado = concorrente_citado IS NOT NULL.
- Ao listar leads, mostre lead_id, nome, empresa, intencao, lead_score e motivo, ordenados por lead_score desc."""

PERGUNTAS = [
    ("Quantos leads de compra imediata chegaram hoje?",
     f"SELECT count(*) AS leads_compra_imediata FROM {G}.leads_classificados "
     f"WHERE intencao = 'compra_imediata' AND data_arquivo = (SELECT max(data_arquivo) FROM {G}.leads_classificados)"),
    ("Qual canal trouxe mais leads de compra imediata?",
     f"SELECT canal, count(*) AS leads_compra_imediata FROM {G}.leads_classificados "
     f"WHERE intencao = 'compra_imediata' AND data_arquivo = (SELECT max(data_arquivo) FROM {G}.leads_classificados) "
     f"GROUP BY canal ORDER BY leads_compra_imediata DESC"),
    ("Quais leads citaram concorrente?",
     f"SELECT lead_id, nome, empresa, concorrente_citado, intencao, lead_score FROM {G}.leads_classificados "
     f"WHERE concorrente_citado IS NOT NULL ORDER BY lead_score DESC"),
    ("Quantos leads da minha fila eu já contatei?",
     f"SELECT f.vendedor, count(DISTINCT f.lead_id) AS na_fila, count(DISTINCT c.lead_id) AS contatados "
     f"FROM {G}.fila_do_dia f LEFT JOIN {G}.feedback_contatos c ON f.lead_id = c.lead_id "
     f"GROUP BY f.vendedor ORDER BY f.vendedor"),
    ("Quais leads de compra imediata ficaram fora da fila de hoje?",
     f"SELECT c.lead_id, c.nome, c.empresa, c.canal, c.lead_score, c.motivo FROM {G}.leads_classificados c "
     f"LEFT ANTI JOIN {G}.fila_do_dia f ON c.lead_id = f.lead_id "
     f"WHERE c.intencao = 'compra_imediata' AND c.data_arquivo = (SELECT max(data_arquivo) FROM {G}.leads_classificados) "
     f"ORDER BY c.lead_score DESC"),
]


def ids(n: int) -> list[str]:
    return sorted(uuid.uuid4().hex for _ in range(n))


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    q_ids, s_ids = ids(len(PERGUNTAS)), ids(len(PERGUNTAS))
    space = {
        "version": 2,
        "config": {
            "sample_questions": [{"id": i, "question": [q]} for i, (q, _) in zip(q_ids, PERGUNTAS)],
        },
        "data_sources": {
            "tables": [{"identifier": t} for t in sorted(
                [f"{G}.feedback_contatos", f"{G}.fila_do_dia", f"{G}.leads_classificados"])],
        },
        "instructions": {
            "text_instructions": [{"id": ids(1)[0], "content": [INSTRUCOES]}],
            "example_question_sqls": [
                {"id": i, "question": [q], "sql": [s]} for i, (q, s) in zip(s_ids, PERGUNTAS)
            ],
        },
    }
    corpo = {
        "warehouse_id": WAREHOUSE,
        "title": TITULO,
        "description": "Agente conversacional sobre os leads do dia: intenção, score, fila e contatos.",
        "serialized_space": json.dumps(space, ensure_ascii=False),
    }
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
        json.dump(corpo, f, ensure_ascii=False)
        arq = f.name
    try:
        out = subprocess.run(
            ["databricks", "genie", "create-space", "--json", "@" + arq, "--profile", PROFILE, "-o", "json"],
            capture_output=True, text=True, encoding="utf-8", shell=(os.name == "nt"),
            env=dict(os.environ, MSYS_NO_PATHCONV="1"),
        )
    finally:
        os.unlink(arq)
    if out.returncode:
        print(out.stderr.strip(), file=sys.stderr)
        return 1
    print(json.loads(out.stdout)["space_id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
