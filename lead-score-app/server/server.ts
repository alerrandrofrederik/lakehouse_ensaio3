import { createApp, analytics, genie, server, getExecutionContext, getWarehouseId } from '@databricks/appkit';

const TABELA_FEEDBACK = 'lh_leadscore_ensaio3.gold.feedback_contatos';

createApp({
  plugins: [analytics(), genie(), server()],
  onPluginsReady(appkit) {
    appkit.server.extend((app) => {
      // RF-14: "Marcar como contatado" grava em gold.feedback_contatos
      app.post('/api/contatos', async (req, res) => {
        const { lead_id, vendedor, resultado } = (req.body ?? {}) as {
          lead_id?: string;
          vendedor?: string;
          resultado?: string;
        };
        if (!lead_id || !vendedor) {
          res.status(400).json({ erro: 'lead_id e vendedor são obrigatórios' });
          return;
        }
        try {
          const { client } = getExecutionContext();
          const warehouseId = await getWarehouseId();
          const r = await client.statementExecution.executeStatement({
            warehouse_id: warehouseId,
            wait_timeout: '30s',
            statement: `INSERT INTO ${TABELA_FEEDBACK} (lead_id, vendedor, contatado_em, resultado)
                        VALUES (:lead_id, :vendedor, current_timestamp(), :resultado)`,
            parameters: [
              { name: 'lead_id', value: lead_id, type: 'STRING' },
              { name: 'vendedor', value: vendedor, type: 'STRING' },
              { name: 'resultado', value: resultado ?? 'contatado', type: 'STRING' },
            ],
          });
          const estado = r.status?.state;
          if (estado !== 'SUCCEEDED') {
            res.status(500).json({ erro: r.status?.error?.message ?? `INSERT em estado ${estado}` });
            return;
          }
          res.json({ ok: true });
        } catch (e) {
          res.status(500).json({ erro: e instanceof Error ? e.message : String(e) });
        }
      });
    });
  },
}).catch(console.error);
