import React from 'react';
import {
  LayoutDashboard,
  Users,
  BarChart3,
  Settings,
  Layers,
  LogOut,
  MessageSquare
} from 'lucide-react';

export default function Sidebar({ activeTab, setActiveTab, onLogout }) {
  const menuItems = [
    { id: 'overview', name: 'Overview Dashboard', icon: LayoutDashboard },
    { id: 'users', name: 'Users Management', icon: Users },
    { id: 'posts', name: 'Posts Audit Logs', icon: MessageSquare },
    { id: 'usage', name: 'API & Usage Monitoring', icon: BarChart3 },
    { id: 'plans', name: 'Subscriptions & Pricing', icon: Settings },
  ];

  return (
    <aside className="w-[260px] h-screen p-6 flex flex-col border-r border-white/5 bg-dark-secondary flex-shrink-0">
      <div className="font-display text-2xl font-extrabold mb-8 flex items-center gap-2.5 bg-gradient-to-r from-accent-purple to-accent-cyan bg-clip-text text-transparent">
        <Layers size={24} className="text-accent-purple" />
        <span>MarketAI Admin</span>
      </div>

      <nav className="flex flex-col gap-1.5 flex-grow">
        {menuItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <div
              key={item.id}
              onClick={() => setActiveTab(item.id)}
              className={`flex items-center gap-3 px-4 py-3 rounded-xl text-[13.5px] font-semibold cursor-pointer select-none transition-all duration-200 ${
                isActive
                  ? 'bg-gradient-to-r from-accent-purple to-dark-tertiary text-white shadow-glow'
                  : 'text-slate-400 hover:text-slate-100 hover:bg-white/5'
              }`}
            >
              <Icon size={18} />
              <span>{item.name}</span>
            </div>
          );
        })}

        <div
          onClick={onLogout}
          className="flex items-center gap-3 px-4 py-3 rounded-xl text-[13.5px] font-semibold cursor-pointer select-none text-accent-pink hover:bg-accent-pink/10 transition-all duration-200 mt-auto"
        >
          <LogOut size={18} />
          <span>Sign Out</span>
        </div>
      </nav>

      <div className="mt-6 pt-4 border-t border-white/5 flex items-center gap-3">
        <div className="w-[38px] h-[38px] rounded-full bg-gradient-to-tr from-accent-cyan to-accent-pink flex items-center justify-center font-display font-bold text-dark-primary text-sm">
          AD
        </div>
        <div className="flex flex-col">
          <span className="text-[13px] font-semibold text-slate-100">Super Admin</span>
          <span className="text-[11px] text-slate-500">System Manager</span>
        </div>
      </div>
    </aside>
  );
}
