import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  BarChart3,
  Settings,
  Layers,
  LogOut,
  MessageSquare
} from 'lucide-react';

export default function Sidebar({ adminUser, onLogout, onCloseMobile }) {
  const menuItems = [
    { id: 'overview', name: 'Overview Dashboard', path: '/', icon: LayoutDashboard },
    { id: 'users', name: 'Users Management', path: '/users', icon: Users },
    { id: 'posts', name: 'Posts Audit Logs', path: '/posts', icon: MessageSquare },
    { id: 'usage', name: 'API & Usage Monitoring', path: '/usage', icon: BarChart3 },
    { id: 'plans', name: 'Subscriptions & Pricing', path: '/plans', icon: Settings },
  ];

  const initials = adminUser?.name 
    ? adminUser.name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase() 
    : 'AD';

  return (
    <aside className="w-[260px] h-screen p-6 flex flex-col border-r border-white/5 bg-dark-secondary flex-shrink-0">
      <NavLink
        to="/"
        onClick={onCloseMobile}
        className="font-display text-2xl font-extrabold mb-8 flex items-center gap-2.5 bg-gradient-to-r from-accent-purple to-accent-cyan bg-clip-text text-transparent cursor-pointer"
      >
        <Layers size={24} className="text-accent-purple" />
        <span>MarketAI Admin</span>
      </NavLink>

      <nav className="flex flex-col gap-1.5 flex-grow">
        {menuItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.id}
              to={item.path}
              end={item.path === '/'}
              onClick={onCloseMobile}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-3 rounded-xl text-[13.5px] font-semibold select-none transition-all duration-200 cursor-pointer ${
                  isActive
                    ? 'bg-gradient-to-r from-accent-purple to-dark-tertiary text-white shadow-glow'
                    : 'text-slate-400 hover:text-slate-100 hover:bg-white/5'
                }`
              }
            >
              <Icon size={18} />
              <span>{item.name}</span>
            </NavLink>
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
          {initials}
        </div>
        <div className="flex flex-col overflow-hidden">
          <span className="text-[13px] font-semibold text-slate-100 truncate">{adminUser?.name || 'Super Admin'}</span>
          <span className="text-[11px] text-slate-500 capitalize">{adminUser?.role || 'System Manager'}</span>
        </div>
      </div>
    </aside>
  );
}

