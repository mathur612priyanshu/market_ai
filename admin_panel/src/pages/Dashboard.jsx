import React, { useState, useEffect } from 'react';
import {
  Users,
  Award,
  DollarSign,
  Database,
  TrendingUp,
  ShieldAlert,
  Flame,
  CreditCard,
  CheckCircle2,
  Calendar
} from 'lucide-react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  BarChart,
  Bar,
  Cell
} from 'recharts';
import { API_BASE_URL } from '../config';

const FacebookIcon = ({ size = 16, ...props }) => (
  <svg viewBox="0 0 24 24" width={size} height={size} stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round" {...props}>
    <path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z" />
  </svg>
);

const InstagramIcon = ({ size = 16, ...props }) => (
  <svg viewBox="0 0 24 24" width={size} height={size} stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round" {...props}>
    <rect x="2" y="2" width="20" height="20" rx="5" ry="5" />
    <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z" />
    <line x1="17.5" y1="6.5" x2="17.51" y2="6.5" />
  </svg>
);

export default function Dashboard({ users }) {
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  const token = localStorage.getItem('admin_token');

  const fetchDashboardSummary = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/admin/dashboard-summary`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      const data = await response.json();
      if (data.success && data.summary) {
        setSummary(data.summary);
      }
    } catch (error) {
      console.error('Error fetching dashboard summary:', error.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardSummary();
  }, [token]);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-sm font-semibold text-slate-400">Loading dynamic metrics from server...</div>
      </div>
    );
  }

  const totalUsers = summary?.totalUsers || users.length || 0;
  const activePro = summary?.activeProUsers || 0;
  const totalRevenue = summary?.totalRevenue || '0.00';
  const totalApiSpend = summary?.totalApiSpend || '0.00';
  const userGrowthData = summary?.userGrowth || [{ name: 'Today', users: totalUsers }];
  const featureUsageData = summary?.featureUsage || [];
  const recentRecharges = summary?.recentRecharges || [];

  const conversionRate = totalUsers > 0 ? ((activePro / totalUsers) * 100).toFixed(1) : '0';

  const statsItems = [
    { 
      title: 'Total Registered Users', 
      value: totalUsers, 
      icon: Users, 
      color: 'text-accent-purple bg-accent-purple/10', 
      delta: `${users.length} active database profiles`, 
      isDeltaUp: true 
    },
    { 
      title: 'Active Pro Subscribers', 
      value: activePro, 
      icon: Award, 
      color: 'text-accent-cyan bg-accent-cyan/10', 
      delta: `${conversionRate}% conversion rate`, 
      isDeltaUp: activePro > 0 
    },
    { 
      title: 'Total Recharge Revenue', 
      value: `₹${totalRevenue}`, 
      icon: DollarSign, 
      color: 'text-accent-green bg-accent-green/10', 
      delta: `${summary?.totalRechargesCount || 0} completed orders`, 
      isDeltaUp: true 
    },
    { 
      title: 'Estimated API Expenses', 
      value: `₹${totalApiSpend}`, 
      icon: Database, 
      color: 'text-accent-pink bg-accent-pink/10', 
      delta: `${(summary?.geminiCalls || 0) + (summary?.apifyCrawls || 0) + (summary?.metaCalls || 0)} total API hits`, 
      isDeltaUp: false 
    },
  ];

  return (
    <div className="animate-fade-in flex flex-col gap-6">
      <header className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold font-display text-slate-100">Overview Dashboard</h1>
          <p className="text-[13.5px] text-slate-400">100% Real-time database telemetry, revenue logs, and usage metrics.</p>
        </div>
      </header>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">
        {statsItems.map((stat, idx) => {
          const Icon = stat.icon;
          return (
            <div key={idx} className="p-5 rounded-2xl bg-dark-secondary border border-white/5 flex flex-col hover:border-accent-purple/35 transition-all duration-200 shadow-sm hover:shadow-glow">
              <div className="flex justify-between items-center mb-3">
                <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">{stat.title}</span>
                <div className={`p-2 rounded-xl flex items-center justify-center ${stat.color}`}>
                  <Icon size={18} />
                </div>
              </div>
              <div className="text-2xl font-extrabold font-display text-slate-100 mb-1.5">{stat.value}</div>
              <div className={`text-[11.5px] flex items-center gap-1 ${stat.isDeltaUp ? 'text-accent-green' : 'text-slate-400'}`}>
                {stat.isDeltaUp && <TrendingUp size={13} />}
                {!stat.isDeltaUp && <ShieldAlert size={13} />}
                <span>{stat.delta}</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Dynamic Charts Grid */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-5">
        <div className="xl:col-span-2 p-6 rounded-2xl bg-dark-secondary border border-white/5 flex flex-col">
          <div className="mb-5">
            <h3 className="text-base font-semibold text-slate-100 font-display">User Base Growth Timeline</h3>
            <p className="text-[11.5px] text-slate-500">Live cumulative registrations from database</p>
          </div>
          <div className="h-[250px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={userGrowthData}>
                <defs>
                  <linearGradient id="purpleGlow" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#9d4edd" stopOpacity={0.4}/>
                    <stop offset="95%" stopColor="#9d4edd" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <XAxis dataKey="name" stroke="#64748b" fontSize={11} tickLine={false} />
                <YAxis stroke="#64748b" fontSize={11} tickLine={false} />
                <Tooltip contentStyle={{ background: '#111524', borderColor: 'rgba(255,255,255,0.08)', borderRadius: '8px' }} />
                <Area type="monotone" dataKey="users" stroke="#9d4edd" strokeWidth={3} fillOpacity={1} fill="url(#purpleGlow)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="p-6 rounded-2xl bg-dark-secondary border border-white/5 flex flex-col">
          <div className="mb-5">
            <h3 className="text-base font-semibold text-slate-100 font-display">Top Feature Breakdown</h3>
            <p className="text-[11.5px] text-slate-500">Real API actions logged in ApiUsages</p>
          </div>
          <div className="h-[250px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={featureUsageData} layout="vertical">
                <XAxis type="number" stroke="#64748b" fontSize={11} tickLine={false} />
                <YAxis dataKey="name" type="category" stroke="#64748b" fontSize={11} tickLine={false} width={110} />
                <Tooltip contentStyle={{ background: '#111524', borderColor: 'rgba(255,255,255,0.08)', borderRadius: '8px' }} />
                <Bar dataKey="count" radius={[0, 6, 6, 0]}>
                  {featureUsageData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.fill} />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Two Column Layout: Recent Recharges & Recent Registrations */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-5">
        {/* Recent Subscriptions / Recharges */}
        <div className="p-6 rounded-2xl bg-dark-secondary border border-white/5">
          <div className="mb-4 flex items-center justify-between">
            <div>
              <h3 className="text-base font-semibold text-slate-100 font-display flex items-center gap-2">
                <CreditCard size={18} className="text-accent-green" />
                Recent Recharge Transactions
              </h3>
              <p className="text-[11.5px] text-slate-500">Live order audit logs from RechargeHistories</p>
            </div>
          </div>
          <div className="w-full overflow-x-auto">
            {recentRecharges.length === 0 ? (
              <div className="py-8 text-center text-slate-500 text-[13px]">No recharges recorded yet.</div>
            ) : (
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-white/5">
                    <th className="py-3 px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400">User / Phone</th>
                    <th className="py-3 px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400">Package</th>
                    <th className="py-3 px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400">Amount</th>
                    <th className="py-3 px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400">Date</th>
                    <th className="py-3 px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {recentRecharges.map(rec => (
                    <tr key={rec.id} className="border-b border-white/5 last:border-b-0 hover:bg-white/[0.01] transition-all">
                      <td className="p-3 text-[12.5px] font-semibold text-slate-200">
                        <div>{rec.User?.name || 'User #' + rec.userId}</div>
                        <div className="text-[10.5px] text-slate-500 font-mono">{rec.User?.phone || rec.transactionId}</div>
                      </td>
                      <td className="p-3 text-[12px] text-slate-300 font-medium">{rec.planName}</td>
                      <td className="p-3 text-[12.5px] font-bold text-accent-green">₹{rec.amount}</td>
                      <td className="p-3 text-[11.5px] text-slate-400">
                        {rec.createdAt ? new Date(rec.createdAt).toLocaleDateString() : 'N/A'}
                      </td>
                      <td className="p-3">
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10.5px] font-semibold bg-accent-green/12 text-accent-green">
                          <CheckCircle2 size={11} />
                          {rec.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Recent Registrations */}
        <div className="p-6 rounded-2xl bg-dark-secondary border border-white/5">
          <div className="mb-4 flex items-center justify-between">
            <div>
              <h3 className="text-base font-semibold text-slate-100 font-display flex items-center gap-2">
                <Users size={18} className="text-accent-purple" />
                Recent User Registrations
              </h3>
              <p className="text-[11.5px] text-slate-500">Latest signed-up accounts</p>
            </div>
          </div>
          <div className="w-full overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-white/5">
                  <th className="py-3 px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400">Name / Phone</th>
                  <th className="py-3 px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400">Joined</th>
                  <th className="py-3 px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400">Plan</th>
                  <th className="py-3 px-3 text-[11px] font-bold uppercase tracking-wider text-slate-400">API Load</th>
                </tr>
              </thead>
              <tbody>
                {users.slice(0, 5).map(user => (
                  <tr key={user.id} className="border-b border-white/5 last:border-b-0 hover:bg-white/[0.01] transition-all">
                    <td className="p-3 text-[12.5px] font-semibold text-slate-200">
                      <div>{user.name}</div>
                      <div className="text-[10.5px] text-slate-500 font-mono">{user.phone}</div>
                    </td>
                    <td className="p-3 text-[12px] text-slate-400">{user.joined}</td>
                    <td className="p-3">
                      <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10.5px] font-semibold ${
                        user.plan === 'Pro' ? 'bg-accent-purple/12 text-accent-purple' :
                        'bg-slate-400/12 text-slate-400'
                      }`}>
                        {user.plan}
                      </span>
                    </td>
                    <td className="p-3">
                      <span className="flex items-center gap-1 text-[11.5px] font-semibold text-slate-200">
                        <Flame size={12} className="text-accent-orange" />
                        {user.usage} ops
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
