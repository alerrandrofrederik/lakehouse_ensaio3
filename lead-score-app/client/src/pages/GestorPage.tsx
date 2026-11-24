import {
  useAnalyticsQuery,
  Alert,
  AlertDescription,
  AlertTitle,
  BarChart,
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  Progress,
  Skeleton,
} from '@databricks/appkit-ui/react';
import { sql } from '@databricks/appkit-ui/js';
import { num, txt, linhas } from '../lib/dados';
import { useVersao } from '../lib/versao';

function Etapa({ rotulo, valor, base, destaque }: { rotulo: string; valor: number; base: number; destaque?: string }) {
  return (
    <div className="space-y-2">
      <div className="flex items-baseline justify-between">
        <span className="text-sm text-muted-foreground">{rotulo}</span>
        <span className="text-2xl font-bold text-foreground tabular-nums">{valor}</span>
      </div>
      <Progress value={base ? (100 * valor) / base : 0} className="h-2" />
      {destaque && <div className="text-xs text-muted-foreground">{destaque}</div>}
    </div>
  );
}

export function GestorPage() {
  const { versao } = useVersao();
  const funil = useAnalyticsQuery('funil', { v: sql.string(versao) });
  const f = linhas(funil.data)[0] ?? {};
  const recebidos = num(f.recebidos);

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-foreground">Visão do Gestor</h2>
        <p className="text-sm text-muted-foreground">
          Funil do dia {txt(f.data) ? `(${f.data})` : ''}: do lead que chega ao contato feito.
        </p>
      </div>

      {funil.error && (
        <Alert variant="destructive">
          <AlertTitle>Erro ao carregar o funil</AlertTitle>
          <AlertDescription>{String(funil.error)}</AlertDescription>
        </Alert>
      )}

      <Card className="shadow-sm">
        <CardHeader>
          <CardTitle>Funil do dia</CardTitle>
          <CardDescription>Recebidos → classificados pela IA → na fila → contatados</CardDescription>
        </CardHeader>
        <CardContent>
          {funil.loading && !funil.data ? (
            <Skeleton className="h-24 w-full" />
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
              <Etapa rotulo="Recebidos" valor={recebidos} base={recebidos} destaque="linhas de CSV do dia" />
              <Etapa rotulo="Classificados" valor={num(f.classificados)} base={recebidos} destaque="leads únicos após deduplicação" />
              <Etapa rotulo="Na fila" valor={num(f.na_fila)} base={recebidos} destaque="capacidade: 4 vendedores × 5" />
              <Etapa rotulo="Contatados" valor={num(f.contatados)} base={recebidos} destaque={`${num(f.contatados)} de ${num(f.na_fila)} da fila`} />
            </div>
          )}
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card className="shadow-sm">
          <CardHeader>
            <CardDescription>Compra imediata hoje</CardDescription>
            <CardTitle className="text-4xl tabular-nums">{num(f.compra_imediata)}</CardTitle>
          </CardHeader>
        </Card>
        <Card className="shadow-sm">
          <CardHeader>
            <CardDescription>Compra imediata fora da fila</CardDescription>
            <CardTitle className="text-4xl tabular-nums text-warning">{num(f.compra_fora_da_fila)}</CardTitle>
          </CardHeader>
          <CardContent className="text-xs text-muted-foreground -mt-2">
            Demanda qualificada que a capacidade de 20 contatos não cobre hoje.
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card className="shadow-sm min-w-0">
          <CardHeader>
            <CardTitle>Leads por intenção</CardTitle>
            <CardDescription>Classificação do ai_classify</CardDescription>
          </CardHeader>
          <CardContent>
            <BarChart queryKey="por_intencao" xKey="intencao" yKey="leads" orientation="horizontal" height={260} />
          </CardContent>
        </Card>
        <Card className="shadow-sm min-w-0">
          <CardHeader>
            <CardTitle>Leads por canal</CardTitle>
            <CardDescription>Que canal traz comprador, não só volume</CardDescription>
          </CardHeader>
          <CardContent>
            <BarChart
              queryKey="por_canal"
              xKey="canal"
              yKey={['compra_imediata', 'avaliando', 'suporte', 'spam']}
              stacked
              orientation="horizontal"
              height={260}
            />
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
