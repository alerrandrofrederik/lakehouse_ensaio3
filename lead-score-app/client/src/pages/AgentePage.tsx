import { GenieChat } from '@databricks/appkit-ui/react';

const PERGUNTAS = [
  'Quantos leads de compra imediata chegaram hoje?',
  'Qual canal trouxe mais leads de compra imediata?',
  'Quais leads citaram concorrente?',
  'Quantos leads da minha fila eu já contatei?',
  'Quais leads de compra imediata ficaram fora da fila de hoje?',
];

export function AgentePage() {
  return (
    <div className="max-w-4xl mx-auto space-y-4">
      <div>
        <h2 className="text-2xl font-bold text-foreground">Agente Comercial</h2>
        <p className="text-sm text-muted-foreground mt-1">
          Pergunte em português sobre os leads do dia. As respostas vêm do Genie sobre as tabelas Gold.
        </p>
      </div>
      <div className="flex flex-wrap gap-2 text-xs">
        {PERGUNTAS.map((p) => (
          <span key={p} className="rounded-full border px-3 py-1 text-muted-foreground">
            {p}
          </span>
        ))}
      </div>
      <div className="h-[min(640px,70vh)] border rounded-lg overflow-hidden">
        <GenieChat alias="default" />
      </div>
    </div>
  );
}
