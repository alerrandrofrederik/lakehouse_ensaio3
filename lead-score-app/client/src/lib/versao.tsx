import { createContext, useCallback, useContext, useState, type ReactNode } from 'react';

// Cache-buster das consultas que dependem de contatos: muda a cada "Contatado".
type Versao = { versao: string; novaVersao: () => void };
const Ctx = createContext<Versao>({ versao: '0', novaVersao: () => {} });

export function VersaoProvider({ children }: { children: ReactNode }) {
  const [versao, setVersao] = useState('0');
  const novaVersao = useCallback(() => setVersao(String(Date.now())), []);
  return <Ctx.Provider value={{ versao, novaVersao }}>{children}</Ctx.Provider>;
}

export const useVersao = () => useContext(Ctx);
