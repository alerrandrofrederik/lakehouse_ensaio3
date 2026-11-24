// O warehouse devolve booleanos e números como texto: normalize antes de usar.
export const bool = (v: unknown): boolean => v === true || v === 'true';
export const num = (v: unknown): number => {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
};
export const txt = (v: unknown): string | null =>
  v === null || v === undefined || v === '' ? null : String(v);

export type Linha = Record<string, unknown>;
export const linhas = (data: unknown): Linha[] => (Array.isArray(data) ? (data as Linha[]) : []);

export const VENDEDORES = ['Ana Ribeiro', 'Bruno Carvalho', 'Carla Mendes', 'Diego Rocha'] as const;

export const INTENCAO_LABEL: Record<string, string> = {
  compra_imediata: 'Compra imediata',
  avaliando: 'Avaliando',
  suporte: 'Suporte',
  spam: 'Spam',
};

export const CANAL_LABEL: Record<string, string> = {
  site: 'Site',
  linkedin: 'LinkedIn',
  evento: 'Evento',
  indicacao: 'Indicação',
  google_ads: 'Google Ads',
};
