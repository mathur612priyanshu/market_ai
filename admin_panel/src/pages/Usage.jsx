import React from 'react';
import {
  Database,
  Globe,
  CheckCircle2,
  XCircle,
  HelpCircle,
  Activity
} from 'lucide-react';

const FacebookIcon = ({ size = 16, ...props }) => (
  <svg viewBox="0 0 24 24" width={size} height={size} stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round" {...props}>
    <path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z" />
  </svg>
);

export default function Usage({ apiCosts, handleUpdateApiCost, usageStats }) {
  const totalGeminiCalls = usageStats ? usageStats.geminiCalls : 0;
  const totalApifyCrawls = usageStats ? usageStats.apifyCrawls : 0;
  const totalMetaRequests = usageStats ? usageStats.metaCalls : 0;

  const usageCards = [
    { title: 'Gemini API Calls', value: totalGeminiCalls, spend: (totalGeminiCalls * apiCosts.geminiCost).toFixed(3), icon: Database, color: 'text-accent-purple bg-accent-purple/10' },
    { title: 'Apify Web Crawls', value: totalApifyCrawls, spend: (totalApifyCrawls * apiCosts.apifyCost).toFixed(2), icon: Globe, color: 'text-accent-cyan bg-accent-cyan/10' },
    { title: 'Meta Graph API Calls', value: totalMetaRequests, spend: (totalMetaRequests * apiCosts.metaCost).toFixed(3), icon: FacebookIcon, color: 'text-accent-green bg-accent-green/10' },
  ];

  const activeIntegrations = usageStats && usageStats.integrations ? usageStats.integrations : {
    gemini: { status: 'disabled', label: 'Checking configurations...' },
    apify: { status: 'disabled', label: 'Checking configurations...' },
    meta: { status: 'disabled', label: 'Checking configurations...' }
  };

  return (
    <div className="animate-fade-in flex flex-col gap-6">
      <header className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold font-display text-slate-100">API & Usage Monitoring</h1>
          <p className="text-[13.5px] text-slate-400">Track server resource consumption, rate-limits, and third-party API provider costs.</p>
        </div>
      </header>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        {usageCards.map((card, idx) => {
          const Icon = card.icon;
          return (
            <div key={idx} className="p-5 rounded-2xl bg-dark-secondary border border-white/5 flex flex-col">
              <div className="flex justify-between items-center mb-3">
                <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">{card.title}</span>
                <div className={`p-2 rounded-xl flex items-center justify-center ${card.color}`}>
                  <Icon size={18} />
                </div>
              </div>
              <div className="text-2xl font-extrabold font-display text-slate-100 mb-1.5">{card.value}</div>
              <div className="text-[11.5px] text-slate-500">
                <span>Estimated Spend: ${card.spend}</span>
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-3 gap-5">
        {/* Cost Settings Form */}
        <div className="xl:col-span-2 p-6 rounded-2xl bg-dark-secondary border border-white/5 flex flex-col">
          <div className="mb-6">
            <h3 className="text-base font-semibold text-slate-100 font-display">Configure API Billing Parameters</h3>
            <p className="text-[11.5px] text-slate-500">Adjust variables to calculate server resource consumption correctly</p>
          </div>

          <div className="flex flex-col gap-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-[12.5px] font-semibold text-slate-400 mb-2">Gemini API Call Unit Cost ($)</label>
                <input
                  type="number"
                  className="w-full px-4 py-2.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-[13px] outline-none focus:border-accent-purple"
                  step="0.0001"
                  value={apiCosts.geminiCost}
                  onChange={(e) => handleUpdateApiCost('geminiCost', e.target.value)}
                />
              </div>
              <div>
                <label className="block text-[12.5px] font-semibold text-slate-400 mb-2">Apify Crawler Unit Cost ($)</label>
                <input
                  type="number"
                  className="w-full px-4 py-2.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-[13px] outline-none focus:border-accent-purple"
                  step="0.01"
                  value={apiCosts.apifyCost}
                  onChange={(e) => handleUpdateApiCost('apifyCost', e.target.value)}
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-[12.5px] font-semibold text-slate-400 mb-2">Meta Graph API Unit Cost ($)</label>
                <input
                  type="number"
                  className="w-full px-4 py-2.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-[13px] outline-none focus:border-accent-purple"
                  step="0.0001"
                  value={apiCosts.metaCost}
                  onChange={(e) => handleUpdateApiCost('metaCost', e.target.value)}
                />
              </div>
              <div>
                <label className="block text-[12.5px] font-semibold text-slate-400 mb-2">Daily Gemini Call Warning Limit</label>
                <input
                  type="number"
                  className="w-full px-4 py-2.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-[13px] outline-none focus:border-accent-purple"
                  value={apiCosts.geminiLimit}
                  onChange={(e) => handleUpdateApiCost('geminiLimit', e.target.value)}
                />
              </div>
            </div>
          </div>
        </div>

        {/* Dynamic Integration Status Checker */}
        <div className="p-6 rounded-2xl bg-dark-secondary border border-white/5 flex flex-col">
          <div className="flex items-center gap-2 mb-4 border-b border-white/5 pb-3">
            <Activity size={18} className="text-accent-cyan" />
            <h3 className="text-sm font-bold text-slate-100 font-display">Live API Integrations Health</h3>
          </div>

          <div className="flex flex-col gap-3.5 text-left">
            {/* Gemini */}
            <div className="p-3 rounded-xl bg-dark-tertiary border border-white/5 flex items-center justify-between">
              <div className="flex flex-col">
                <span className="text-[12.5px] font-bold text-slate-200">Google Gemini AI</span>
                <span className="text-[11px] text-slate-500">{activeIntegrations.gemini.label}</span>
              </div>
              {activeIntegrations.gemini.status === 'active' ? (
                <CheckCircle2 size={18} className="text-accent-green" />
              ) : (
                <XCircle size={18} className="text-accent-pink" />
              )}
            </div>

            {/* Apify */}
            <div className="p-3 rounded-xl bg-dark-tertiary border border-white/5 flex items-center justify-between">
              <div className="flex flex-col">
                <span className="text-[12.5px] font-bold text-slate-200">Apify Ads Crawler</span>
                <span className="text-[11px] text-slate-500">{activeIntegrations.apify.label}</span>
              </div>
              {activeIntegrations.apify.status === 'active' ? (
                <CheckCircle2 size={18} className="text-accent-green" />
              ) : (
                <XCircle size={18} className="text-accent-pink" />
              )}
            </div>

            {/* Meta */}
            <div className="p-3 rounded-xl bg-dark-tertiary border border-white/5 flex items-center justify-between">
              <div className="flex flex-col">
                <span className="text-[12.5px] font-bold text-slate-200">Meta Graph API App</span>
                <span className="text-[11px] text-slate-500">{activeIntegrations.meta.label}</span>
              </div>
              {activeIntegrations.meta.status === 'active' ? (
                <CheckCircle2 size={18} className="text-accent-green" />
              ) : (
                <XCircle size={18} className="text-accent-pink" />
              )}
            </div>
          </div>
          <span className="text-[10px] text-slate-500 mt-auto pt-4 text-center">Status updates automatically on admin panel sync</span>
        </div>
      </div>
    </div>
  );
}
