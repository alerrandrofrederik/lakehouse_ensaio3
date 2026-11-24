import { useState } from 'react';
import {
  useAnalyticsQuery,
  Alert,
  AlertDescription,
  AlertTitle,
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
  Progress,
  Skeleton,
} from '@databricks/appkit-ui/react';
import { sql } from '@databricks/appkit-ui/js';
import { CheckCircle2, Phone, Sparkles } from 'lucide-react';
import { bool, num, txt, linhas, VENDEDORES, INTENCAO_LABEL, CANAL_LABEL, type Linha } from '../lib/dados';
import { useVersao } from '../lib/versao';

const TODOS = 'Todos';

function Componente({ nome, valor, peso }: { nome: string; valor: number; peso: string }) {
  return (
    <div className="space-y-1">
      <div className="flex justify-between text-xs text-muted-foreground">
        <span>
          {nome} <span className="opacity-60">({peso})</span>
        </span>
        <span className="font-medium text-foreground">{valor}</span>
      </div>
      <Progress value={valor} className="h-1.5" />
    </div>
  );
}

function Entidade({ rotulo, valor }: { rotulo: string; valor: string | null }) {
  if (!valor) return null;
  return (
    <div className="text-xs">
      <span className="text-muted-foreground">{rotulo}: </span>
      <span className="font-medium text-foreground">{valor}</span>
    </div>
  );
}

function LeadCard({ l, onContatado }: { l: Linha; onContatado: (l: Linha) => Promise<void> }) {
  const [enviando, setEnviando] = useState(false);
  const contatado = bool(l.contatado);
  const compra = l.intencao === 'compra_imediata';
  const posicao = num(l.posicao);
  const orcamento = bool(l.orcamento_aprovado);

  return (
    <Card className={`shadow-sm ${posicao === 1 ? 'ring-2 ring-brand' : ''}`}>
      <CardHeader className="pb-3">
        <div className="flex items-start gap-4">
          <div className="flex flex-col items-center">
            <div className="text-xs text-muted-foreground">#{posicao}</div>
            <div className="text-3xl font-bold text-foreground tabular-nums">{num(l.lead_score)}</div>
            <div className="text-[10px] uppercase tracking-wide text-muted-foreground">score</div>
          </div>
          <div className="flex-1 min-w-0 space-y-1">
            <div className="flex flex-wrap items-center gap-2">
              <span className="font-semibold text-foreground">{txt(l.nome)}</span>
              <Badge className={compra ? 'bg-success text-success-foreground' : 'bg-warning text-warning-foreground'}>
                {INTENCAO_LABEL[String(l.intencao)] ?? String(l.intencao)}
              </Badge>
              {contatado && (
                <Badge variant="outline" className="gap-1">
                  <CheckCircle2 className="h-3 w-3" /> Contatado
                </Badge>
              )}
            </div>
            <div className="text-sm text-muted-foreground truncate">
              {[txt(l.cargo), txt(l.empresa), txt(l.porte) && `porte ${l.porte}`].filter(Boolean).join(' · ')}
            </div>
            <div className="text-xs text-muted-foreground">
              {CANAL_LABEL[String(l.canal)] ?? txt(l.canal)} · chegou às {txt(l.hora) ?? '—'} · {txt(l.vendedor)}
            </div>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex gap-2 text-sm">
          <Sparkles className="h-4 w-4 mt-0.5 shrink-0 text-brand" />
          <span className="text-foreground">{txt(l.motivo)}</span>
        </div>
        <blockquote className="text-sm italic text-muted-foreground border-l-2 pl-3 line-clamp-3">
          “{txt(l.mensagem)}”
        </blockquote>
        <div className="grid grid-cols-2 gap-x-4 gap-y-1">
          <Entidade rotulo="Produto" valor={txt(l.produto)} />
          <Entidade rotulo="Licenças" valor={txt(l.qtd_licencas)} />
          <Entidade rotulo="Prazo" valor={txt(l.prazo)} />
          <Entidade rotulo="Orçamento" valor={orcamento ? 'aprovado' : null} />
          <Entidade rotulo="Concorrente" valor={txt(l.concorrente_citado)} />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Componente nome="Intenção" peso="50%" valor={num(l.c_intencao)} />
          <Componente nome="Perfil" peso="25%" valor={num(l.c_perfil)} />
          <Componente nome="Sinais" peso="15%" valor={num(l.c_sinais)} />
          <Componente nome="Recência" peso="10%" valor={num(l.c_recencia)} />
        </div>
        <div className="flex flex-wrap items-center justify-between gap-2 pt-1 border-t">
          <div className="flex items-center gap-2 text-sm pt-3">
            <Phone className="h-4 w-4 text-muted-foreground" />
            <span className="font-medium text-foreground">{txt(l.proximo_passo)}</span>
          </div>
          <Button
            size="sm"
            className="mt-3"
            variant={contatado ? 'outline' : 'default'}
            disabled={contatado || enviando}
            onClick={async () => {
              setEnviando(true);
              try {
                await onContatado(l);
              } finally {
                setEnviando(false);
              }
            }}
          >
            {contatado ? 'Contatado' : enviando ? 'Gravando…' : 'Marcar como contatado'}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

export function FilaPage() {
  const { versao, novaVersao } = useVersao();
  const [vendedor, setVendedor] = useState<string>(TODOS);
  const [erroContato, setErroContato] = useState<string | null>(null);
  const { data, loading, error } = useAnalyticsQuery('fila_do_dia', { v: sql.string(versao) });
  const fila = linhas(data);
  const visiveis = vendedor === TODOS ? fila : fila.filter((l) => l.vendedor === vendedor);
  const contatados = visiveis.filter((l) => bool(l.contatado)).length;

  async function marcar(l: Linha) {
    setErroContato(null);
    const r = await fetch('/api/contatos', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ lead_id: l.lead_id, vendedor: l.vendedor, resultado: 'contatado' }),
    });
    if (!r.ok) {
      const corpo = (await r.json().catch(() => ({}))) as { erro?: string };
      setErroContato(corpo.erro ?? `Falha ao gravar (${r.status})`);
      return;
    }
    novaVersao();
  }

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-foreground">Fila do Dia</h2>
          <p className="text-sm text-muted-foreground">
            Os 20 leads com maior chance de compra, 5 por vendedor. Ligue de cima para baixo.
          </p>
        </div>
        <div className="flex flex-wrap gap-1">
          {[TODOS, ...VENDEDORES].map((v) => (
            <Button key={v} size="sm" variant={vendedor === v ? 'default' : 'outline'} onClick={() => setVendedor(v)}>
              {v}
            </Button>
          ))}
        </div>
      </div>

      {!loading && !error && visiveis.length > 0 && (
        <div className="flex items-center gap-3 text-sm text-muted-foreground">
          <span>
            {contatados} de {visiveis.length} contatados
          </span>
          <Progress value={(100 * contatados) / visiveis.length} className="h-2 max-w-xs" />
        </div>
      )}

      {erroContato && (
        <Alert variant="destructive">
          <AlertTitle>Não foi possível marcar como contatado</AlertTitle>
          <AlertDescription>{erroContato}</AlertDescription>
        </Alert>
      )}
      {error && (
        <Alert variant="destructive">
          <AlertTitle>Erro ao carregar a fila</AlertTitle>
          <AlertDescription>{String(error)}</AlertDescription>
        </Alert>
      )}
      {loading && fila.length === 0 && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {Array.from({ length: 4 }, (_, i) => (
            <Skeleton key={i} className="h-72 w-full" />
          ))}
        </div>
      )}
      {!loading && !error && visiveis.length === 0 && (
        <Empty>
          <EmptyHeader>
            <EmptyTitle>Fila vazia</EmptyTitle>
            <EmptyDescription>Os leads do dia ainda não foram processados pelo pipeline.</EmptyDescription>
          </EmptyHeader>
        </Empty>
      )}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {visiveis.map((l) => (
          <LeadCard key={String(l.lead_id)} l={l} onContatado={marcar} />
        ))}
      </div>
    </div>
  );
}
