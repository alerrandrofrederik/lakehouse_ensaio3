import { createBrowserRouter, RouterProvider, NavLink, Outlet } from 'react-router';
import { ListOrdered, LayoutDashboard, MessageSquareText, Target } from 'lucide-react';
import { FilaPage } from './pages/FilaPage';
import { GestorPage } from './pages/GestorPage';
import { AgentePage } from './pages/AgentePage';
import { VersaoProvider } from './lib/versao';

const itens = [
  { to: '/', label: 'Fila do Dia', icon: ListOrdered, end: true },
  { to: '/gestor', label: 'Visão do Gestor', icon: LayoutDashboard, end: false },
  { to: '/agente', label: 'Agente Comercial', icon: MessageSquareText, end: false },
];

const linkClass = ({ isActive }: { isActive: boolean }) =>
  `flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
    isActive ? 'bg-white/15 text-white' : 'text-white/70 hover:bg-white/10 hover:text-white'
  }`;

function Layout() {
  return (
    <div className="min-h-screen bg-background flex flex-col md:flex-row">
      <aside className="md:w-60 shrink-0 bg-[#0f2341] text-white flex md:flex-col">
        <div className="flex items-center gap-2 px-5 py-5">
          <Target className="h-6 w-6 text-sky-300" />
          <div>
            <div className="text-lg font-bold leading-tight">Lead Score</div>
            <div className="text-xs text-white/60 hidden md:block">Atlas Software · Comercial</div>
          </div>
        </div>
        <nav className="flex md:flex-col gap-1 px-3 pb-3 md:pb-0 overflow-x-auto">
          {itens.map(({ to, label, icon: Icon, end }) => (
            <NavLink key={to} to={to} end={end} className={linkClass}>
              <Icon className="h-4 w-4 shrink-0" />
              <span className="whitespace-nowrap">{label}</span>
            </NavLink>
          ))}
        </nav>
        <div className="mt-auto px-5 py-4 text-xs text-white/50 hidden md:block">
          100 leads por dia · capacidade para 20
        </div>
      </aside>
      <main className="flex-1 min-w-0 p-4 md:p-8">
        <Outlet />
      </main>
    </div>
  );
}

const router = createBrowserRouter([
  {
    element: <Layout />,
    children: [
      { path: '/', element: <FilaPage /> },
      { path: '/gestor', element: <GestorPage /> },
      { path: '/agente', element: <AgentePage /> },
    ],
  },
]);

export default function App() {
  return (
    <VersaoProvider>
      <RouterProvider router={router} />
    </VersaoProvider>
  );
}
