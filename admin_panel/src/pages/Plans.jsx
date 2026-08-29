import React from 'react';
import {
  CheckCircle,
  Lock
} from 'lucide-react';

export default function Plans({ plans, handleUpdatePlanLimit }) {
  return (
    <div className="animate-fade-in flex flex-col gap-6">
      <header className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold font-display text-slate-100">Subscriptions & Pricing Configuration</h1>
          <p className="text-[13.5px] text-slate-400">Configure subscription plans, set API usage quotas, and manage active paywall limits.</p>
        </div>
      </header>

      {/* Plans Grid */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        {plans.map(plan => (
          <div className={`p-7 rounded-2xl bg-dark-secondary border flex flex-col relative transition-all duration-200 hover:-translate-y-1 ${
            plan.id === 'pro' ? 'border-accent-purple shadow-glow' : 'border-white/5'
          }`} key={plan.id}>
            {plan.id === 'pro' && (
              <div className="absolute top-4 right-4 bg-accent-purple/15 text-accent-purple px-2 py-1 rounded-md text-[10px] font-bold tracking-wide uppercase">
                POPULAR
              </div>
            )}
            <div className="font-display text-xl font-bold text-slate-100 mb-1.5">{plan.name}</div>
            <p className="text-[12px] text-slate-500 mb-5">Feature limits & API quotas</p>

            <div className="my-4 flex items-baseline gap-1">
              <span className="font-display text-4xl font-extrabold text-slate-100">${plan.price}</span>
              <span className="text-[12.5px] text-slate-500">/ month</span>
            </div>

            <div className="flex flex-col gap-3 my-5 flex-grow">
              <div className="flex items-center gap-2.5 text-[12.5px] text-slate-300">
                <CheckCircle size={14} className="text-accent-green" />
                <span>{plan.adsLimit === 999 ? 'Unlimited' : `${plan.adsLimit} Ad Copies /mo`}</span>
              </div>
              <div className="flex items-center gap-2.5 text-[12.5px] text-slate-300">
                <CheckCircle size={14} className="text-accent-green" />
                <span>{plan.spyLimit === 999 ? 'Unlimited' : `${plan.spyLimit} Competitor Spies /mo`}</span>
              </div>
              <div className="flex items-center gap-2.5 text-[12.5px] text-slate-300">
                <CheckCircle size={14} className="text-accent-green" />
                <span>{plan.postsLimit === 999 ? 'Unlimited' : `${plan.postsLimit} Scheduled Posts /mo`}</span>
              </div>
              <div className="flex items-center gap-2.5 text-[12.5px] text-slate-300">
                <CheckCircle size={14} className="text-accent-green" />
                <span>{plan.leadsLimit === 9999 ? 'Unlimited' : `${plan.leadsLimit} Lead Syncs /mo`}</span>
              </div>
            </div>

            <div className="border-t border-white/5 pt-4 flex flex-col gap-3">
              <div className="flex flex-col gap-1.5">
                <label className="text-[11px] font-semibold text-slate-400">Monthly Price ($)</label>
                <input
                  type="number"
                  className="w-full px-3 py-1.5 rounded-lg bg-dark-tertiary border border-white/5 text-slate-100 text-xs outline-none focus:border-accent-purple"
                  value={plan.price}
                  onChange={(e) => handleUpdatePlanLimit(plan.id, 'price', e.target.value)}
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div className="flex flex-col gap-1.5">
                  <label className="text-[11px] font-semibold text-slate-400">Ad Limit</label>
                  <input
                    type="number"
                    className="w-full px-3 py-1.5 rounded-lg bg-dark-tertiary border border-white/5 text-slate-100 text-xs outline-none focus:border-accent-purple"
                    value={plan.adsLimit}
                    onChange={(e) => handleUpdatePlanLimit(plan.id, 'adsLimit', e.target.value)}
                  />
                </div>
                <div className="flex flex-col gap-1.5">
                  <label className="text-[11px] font-semibold text-slate-400">Spy Limit</label>
                  <input
                    type="number"
                    className="w-full px-3 py-1.5 rounded-lg bg-dark-tertiary border border-white/5 text-slate-100 text-xs outline-none focus:border-accent-purple"
                    value={plan.spyLimit}
                    onChange={(e) => handleUpdatePlanLimit(plan.id, 'spyLimit', e.target.value)}
                  />
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Paywall Preview Simulator */}
      <div className="p-6 rounded-2xl bg-gradient-to-r from-accent-purple/5 to-accent-cyan/5 border border-accent-purple/20 flex flex-col items-center text-center mt-4">
        <div className="w-12 h-12 rounded-full bg-accent-purple/15 text-accent-purple flex items-center justify-center mb-4">
          <Lock size={20} />
        </div>
        <h3 className="text-lg font-bold font-display text-slate-100 mb-1.5">Mobile Paywall Shield Active</h3>
        <p className="text-[13px] text-slate-400 max-w-[520px] leading-relaxed mb-4">
          When a Free user hits their monthly limit of <strong>{plans[0].adsLimit} ads</strong> or <strong>{plans[0].spyLimit} competitor searches</strong>, the Flutter mobile app will automatically lock the feature and trigger the subscription upgrade layout.
        </p>
        <div className="flex gap-2">
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold tracking-wide bg-accent-purple/12 text-accent-purple">
            Limit Shield Connected
          </span>
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold tracking-wide bg-accent-green/12 text-accent-green">
            Paywalls Active
          </span>
        </div>
      </div>
    </div>
  );
}
