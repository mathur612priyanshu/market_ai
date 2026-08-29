import React from 'react';
import {
  Users,
  Award,
  DollarSign,
  Database,
  TrendingUp,
  ShieldAlert,
  Flame
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

export default function Dashboard({ users, plans, apiCosts }) {
  // Chart Data
  const userGrowthData = [
    { name: 'July 25', users: 12 },
    { name: 'July 30', users: 19 },
    { name: 'Aug 05', users: 27 },
    { name: 'Aug 10', users: 42 },
    { name: 'Aug 15', users: 58 },
    { name: 'Aug 20', users: 84 },
    { name: 'Aug 25', users: 112 },
  ];

  const featureUsageData = [
    { name: 'Ad Generator', count: 542, fill: '#9d4edd' },
    { name: 'Competitor Spy', count: 320, fill: '#5390d9' },
    { name: 'Post Scheduler', count: 180, fill: '#4cc9f0' },
    { name: 'Leads Sync', count: 412, fill: '#06d6a0' },
  ];

  // Calculations
  const activeSubscribersCount = users.filter(u => u.plan !== 'Free' && u.status === 'active').length;
  
  const monthlyRevenue = plans.reduce((acc, plan) => {
    const planUsers = users.filter(u => u.plan.toLowerCase() === plan.name.split(' ')[0].toLowerCase() || (u.plan === 'Pro' && plan.id === 'pro') || (u.plan === 'Enterprise' && plan.id === 'enterprise'));
    return acc + (planUsers.length * plan.price);
  }, 0);

  const totalGeminiCalls = 1450;
  const totalApifyCrawls = 680;
  const totalMetaRequests = 2890;

  const totalApiSpend = (
    (totalGeminiCalls * apiCosts.geminiCost) +
    (totalApifyCrawls * apiCosts.apifyCost) +
    (totalMetaRequests * apiCosts.metaCost)
  ).toFixed(2);

  const statsItems = [
    { title: 'Total Registered Users', value: users.length, icon: Users, color: 'text-accent-purple bg-accent-purple/10', delta: '+24% vs last week', isDeltaUp: true },
    { title: 'Active Subscribers', value: activeSubscribersCount, icon: Award, color: 'text-accent-cyan bg-accent-cyan/10', delta: '57.1% conversion rate', isDeltaUp: true },
    { title: 'Monthly Recur. Revenue', value: `$${monthlyRevenue}`, icon: DollarSign, color: 'text-accent-green bg-accent-green/10', delta: '+18% profit margins', isDeltaUp: true },
    { title: 'API Server Expenses', value: `$${totalApiSpend}`, icon: Database, color: 'text-accent-pink bg-accent-pink/10', delta: 'Google & Apify billing active', isDeltaUp: false },
  ];

  return (
    <div className="animate-fade-in flex flex-col gap-6">
      <header className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold font-display text-slate-100">Overview Dashboard</h1>
          <p className="text-[13.5px] text-slate-400">Real-time telemetry, platform stats, and system performance metrics.</p>
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
              <div className={`text-[11.5px] flex items-center gap-1 ${stat.isDeltaUp ? 'text-accent-green' : 'text-slate-500'}`}>
                {stat.isDeltaUp && <TrendingUp size={13} />}
                {!stat.isDeltaUp && <ShieldAlert size={13} />}
                <span>{stat.delta}</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-5">
        <div className="xl:col-span-2 p-6 rounded-2xl bg-dark-secondary border border-white/5 flex flex-col">
          <div className="mb-5">
            <h3 className="text-base font-semibold text-slate-100 font-display">User Base Accumulation</h3>
            <p className="text-[11.5px] text-slate-500">Total users over the past 30 days</p>
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
            <h3 className="text-base font-semibold text-slate-100 font-display">Top Feature Hits</h3>
            <p className="text-[11.5px] text-slate-500">AI integrations usage breakdown</p>
          </div>
          <div className="h-[250px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={featureUsageData} layout="vertical">
                <XAxis type="number" stroke="#64748b" fontSize={11} tickLine={false} />
                <YAxis dataKey="name" type="category" stroke="#64748b" fontSize={11} tickLine={false} width={100} />
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

      {/* Recent activity list */}
      <div className="p-6 rounded-2xl bg-dark-secondary border border-white/5">
        <div className="mb-4">
          <h3 className="text-base font-semibold text-slate-100 font-display">Recent Registrations</h3>
        </div>
        <div className="w-full overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-white/5">
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">User Name</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Email ID</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Joined Date</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Social Channels</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Billing Plan</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">API Load</th>
              </tr>
            </thead>
            <tbody>
              {users.slice(0, 4).map(user => (
                <tr key={user.id} className="border-b border-white/5 last:border-b-0 hover:bg-white/[0.01] transition-all">
                  <td className="p-4 text-[13px] font-semibold text-slate-200">{user.name}</td>
                  <td className="p-4 text-[13px] text-slate-400">{user.email}</td>
                  <td className="p-4 text-[13px] text-slate-400">{user.joined}</td>
                  <td className="p-4">
                    <div className="flex gap-2 text-slate-400">
                      {user.platforms.includes('facebook') && <FacebookIcon size={16} />}
                      {user.platforms.includes('instagram') && <InstagramIcon size={16} />}
                      {user.platforms.length === 0 && <span className="text-slate-500 text-[11.5px]">None</span>}
                    </div>
                  </td>
                  <td className="p-4">
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold tracking-wide ${
                      user.plan === 'Enterprise' ? 'bg-accent-cyan/12 text-accent-cyan' :
                      user.plan === 'Pro' ? 'bg-accent-purple/12 text-accent-purple' :
                      'bg-slate-400/12 text-slate-400'
                    }`}>
                      {user.plan}
                    </span>
                  </td>
                  <td className="p-4">
                    <span className="flex items-center gap-1 text-[12px] font-semibold text-slate-200">
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
  );
}
