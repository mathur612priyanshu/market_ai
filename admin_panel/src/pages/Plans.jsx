import React, { useState, useEffect } from 'react';
import {
  CheckCircle,
  Lock,
  Save,
  Percent,
  Calendar,
  AlertCircle,
  Database
} from 'lucide-react';
import { API_BASE_URL } from '../config';

export default function Plans() {
  const [config, setConfig] = useState({
    base_day_price: 50.0,
    discount_1_month: 10,
    discount_3_months: 20,
    discount_6_months: 30,
    discount_12_months: 40,
    free_daily_posts_limit: 3,
    free_monthly_watchlist_limit: 5
  });

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const token = localStorage.getItem('admin_token');

  // Fetch current pricing configurations from backend
  const fetchConfig = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/plans/config`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      const data = await response.json();
      if (data.success && data.config) {
        setConfig(data.config);
      }
    } catch (error) {
      console.error('Error fetching plans config:', error.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchConfig();
  }, []);

  const handleInputChange = (key, value) => {
    setConfig(prev => ({
      ...prev,
      [key]: value === '' ? '' : Number(value)
    }));
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setSaving(true);
    setMessage('');
    try {
      const response = await fetch(`${API_BASE_URL}/api/plans/config`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(config)
      });
      const data = await response.json();
      if (data.success) {
        setConfig(data.config);
        setMessage('Configurations saved successfully!');
        setTimeout(() => setMessage(''), 3000);
      } else {
        setMessage('Failed to save configuration: ' + data.error);
      }
    } catch (error) {
      console.error('Error saving plans config:', error.message);
      setMessage('Network error. Failed to save.');
    } finally {
      setSaving(false);
    }
  };

  // Helper to calculate pricing packages preview
  const calculatePackage = (days, discountPercent) => {
    const original = days * (config.base_day_price || 0);
    const discount = original * ((discountPercent || 0) / 100);
    const final = original - discount;
    return {
      original: Math.round(original),
      discount: Math.round(discount),
      final: Math.round(final)
    };
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64 text-slate-400">
        <span className="animate-spin mr-2">⚙️</span> Loading pricing configurations...
      </div>
    );
  }

  const p1 = calculatePackage(30, config.discount_1_month);
  const p3 = calculatePackage(90, config.discount_3_months);
  const p6 = calculatePackage(180, config.discount_6_months);
  const p12 = calculatePackage(365, config.discount_12_months);

  return (
    <div className="animate-fade-in flex flex-col gap-6 font-sans">
      <header className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold font-display text-slate-100">Dynamic Subscriptions Configurator</h1>
          <p className="text-[13px] text-slate-400">Configure base price, packages discounts, and free limits dynamically stored in the database.</p>
        </div>
      </header>

      {message && (
        <div className={`p-4 rounded-xl text-xs font-semibold ${
          message.includes('success') 
            ? 'bg-accent-green/10 text-accent-green border border-accent-green/20' 
            : 'bg-accent-red/10 text-accent-red border border-accent-red/20'
        }`}>
          {message}
        </div>
      )}

      <form onSubmit={handleSave} className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Base Pricing Card */}
        <div className="p-7 rounded-2xl bg-dark-secondary border border-white/5 flex flex-col gap-5">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-accent-purple/10 text-accent-purple">
              <Calendar size={20} />
            </div>
            <div>
              <h3 className="font-display text-base font-bold text-slate-100">Base Unit Cost</h3>
              <p className="text-[11px] text-slate-500">Base price calculated per single active day</p>
            </div>
          </div>

          <div className="flex flex-col gap-2 mt-2">
            <label className="text-xs font-semibold text-slate-400">Base Cost Per Day (INR/USD)</label>
            <div className="relative">
              <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500 text-xs font-bold">₹</span>
              <input
                type="number"
                required
                min="0.1"
                step="0.1"
                className="w-full pl-8 pr-4 py-2.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-sm outline-none focus:border-accent-purple focus:ring-1 focus:ring-accent-purple/20"
                value={config.base_day_price}
                onChange={(e) => handleInputChange('base_day_price', e.target.value)}
              />
            </div>
          </div>

          <div className="p-4 rounded-xl bg-white/3 border border-white/5 flex flex-col gap-2.5 mt-2">
            <div className="flex justify-between items-center text-xs">
              <span className="text-slate-400">1 Day Base Price</span>
              <span className="font-mono text-slate-200 font-bold">₹{config.base_day_price}</span>
            </div>
            <div className="flex justify-between items-center text-xs">
              <span className="text-slate-400">30 Days (No discount)</span>
              <span className="font-mono text-slate-200 font-bold">₹{config.base_day_price * 30}</span>
            </div>
            <div className="flex justify-between items-center text-xs">
              <span className="text-slate-400">365 Days (No discount)</span>
              <span className="font-mono text-slate-200 font-bold">₹{config.base_day_price * 365}</span>
            </div>
          </div>
        </div>

        {/* Discounts Card */}
        <div className="p-7 rounded-2xl bg-dark-secondary border border-white/5 flex flex-col gap-4 lg:col-span-2">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2.5 rounded-xl bg-accent-cyan/10 text-accent-cyan">
              <Percent size={20} />
            </div>
            <div>
              <h3 className="font-display text-base font-bold text-slate-100">Package Duration Discounts</h3>
              <p className="text-[11px] text-slate-500">Configure promotional discounts applied to cumulative durations</p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex flex-col gap-2">
              <label className="text-xs font-semibold text-slate-400">1 Month Plan Discount (%)</label>
              <input
                type="number"
                min="0"
                max="100"
                className="w-full px-4 py-2.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-sm outline-none focus:border-accent-purple"
                value={config.discount_1_month}
                onChange={(e) => handleInputChange('discount_1_month', e.target.value)}
              />
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-xs font-semibold text-slate-400">3 Months Plan Discount (%)</label>
              <input
                type="number"
                min="0"
                max="100"
                className="w-full px-4 py-2.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-sm outline-none focus:border-accent-purple"
                value={config.discount_3_months}
                onChange={(e) => handleInputChange('discount_3_months', e.target.value)}
              />
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-xs font-semibold text-slate-400">6 Months Plan Discount (%)</label>
              <input
                type="number"
                min="0"
                max="100"
                className="w-full px-4 py-2.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-sm outline-none focus:border-accent-purple"
                value={config.discount_6_months}
                onChange={(e) => handleInputChange('discount_6_months', e.target.value)}
              />
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-xs font-semibold text-slate-400">12 Months Plan Discount (%)</label>
              <input
                type="number"
                min="0"
                max="100"
                className="w-full px-4 py-2.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-sm outline-none focus:border-accent-purple"
                value={config.discount_12_months}
                onChange={(e) => handleInputChange('discount_12_months', e.target.value)}
              />
            </div>
          </div>
        </div>

        {/* Free Plan Limits Card */}
        <div className="p-7 rounded-2xl bg-dark-secondary border border-white/5 flex flex-col gap-5">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-accent-pink/10 text-accent-pink">
              <AlertCircle size={20} />
            </div>
            <div>
              <h3 className="font-display text-base font-bold text-slate-100">Free Tier Usage Quotas</h3>
              <p className="text-[11px] text-slate-500">Limits enforced before paywall triggers</p>
            </div>
          </div>

          <div className="flex flex-col gap-4 mt-2">
            <div className="flex flex-col gap-2">
              <label className="text-xs font-semibold text-slate-400">Daily AI Post Generations</label>
              <input
                type="number"
                min="1"
                className="w-full px-4 py-2.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-sm outline-none focus:border-accent-purple"
                value={config.free_daily_posts_limit}
                onChange={(e) => handleInputChange('free_daily_posts_limit', e.target.value)}
              />
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-xs font-semibold text-slate-400">Monthly Competitor Queries</label>
              <input
                type="number"
                min="1"
                className="w-full px-4 py-2.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-sm outline-none focus:border-accent-purple"
                value={config.free_monthly_watchlist_limit}
                onChange={(e) => handleInputChange('free_monthly_watchlist_limit', e.target.value)}
              />
            </div>
          </div>
        </div>

        {/* Package Calculations Preview Table */}
        <div className="p-7 rounded-2xl bg-dark-secondary border border-white/5 flex flex-col gap-4 lg:col-span-2">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-accent-green/10 text-accent-green">
              <Database size={20} />
            </div>
            <div>
              <h3 className="font-display text-base font-bold text-slate-100">Calculated Packages Preview</h3>
              <p className="text-[11px] text-slate-500">Live preview of packages rendered to users during payment checkouts</p>
            </div>
          </div>

          <div className="overflow-x-auto mt-2">
            <table className="w-full text-left text-xs text-slate-300">
              <thead>
                <tr className="border-b border-white/5 text-slate-400 uppercase tracking-wider text-[10px] font-semibold">
                  <th className="py-2.5">Duration</th>
                  <th className="py-2.5">Original</th>
                  <th className="py-2.5 text-accent-pink">Discount</th>
                  <th className="py-2.5 text-accent-green">Final Price</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                <tr>
                  <td className="py-3 font-semibold text-slate-200">1 Month (30 days)</td>
                  <td className="py-3 font-mono">₹{p1.original}</td>
                  <td className="py-3 font-mono text-accent-pink">-{config.discount_1_month}% (₹{p1.discount})</td>
                  <td className="py-3 font-mono text-accent-green font-bold">₹{p1.final}</td>
                </tr>
                <tr>
                  <td className="py-3 font-semibold text-slate-200">3 Months (90 days)</td>
                  <td className="py-3 font-mono">₹{p3.original}</td>
                  <td className="py-3 font-mono text-accent-pink">-{config.discount_3_months}% (₹{p3.discount})</td>
                  <td className="py-3 font-mono text-accent-green font-bold">₹{p3.final}</td>
                </tr>
                <tr>
                  <td className="py-3 font-semibold text-slate-200">6 Months (180 days)</td>
                  <td className="py-3 font-mono">₹{p6.original}</td>
                  <td className="py-3 font-mono text-accent-pink">-{config.discount_6_months}% (₹{p6.discount})</td>
                  <td className="py-3 font-mono text-accent-green font-bold">₹{p6.final}</td>
                </tr>
                <tr>
                  <td className="py-3 font-semibold text-slate-200">1 Year (365 days)</td>
                  <td className="py-3 font-mono">₹{p12.original}</td>
                  <td className="py-3 font-mono text-accent-pink">-{config.discount_12_months}% (₹{p12.discount})</td>
                  <td className="py-3 font-mono text-accent-green font-bold">₹{p12.final}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div className="lg:col-span-3 flex justify-end">
          <button
            type="submit"
            disabled={saving}
            className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-accent-purple hover:bg-accent-purple-hover text-white text-xs font-semibold cursor-pointer transition-all shadow-glow disabled:opacity-50"
          >
            <Save size={15} />
            <span>{saving ? 'Saving...' : 'Save Configurations'}</span>
          </button>
        </div>
      </form>

      {/* Paywall Preview Simulator */}
      <div className="p-6 rounded-2xl bg-gradient-to-r from-accent-purple/5 to-accent-cyan/5 border border-accent-purple/20 flex flex-col items-center text-center mt-2">
        <div className="w-12 h-12 rounded-full bg-accent-purple/15 text-accent-purple flex items-center justify-center mb-4">
          <Lock size={20} />
        </div>
        <h3 className="text-lg font-bold font-display text-slate-100 mb-1.5">Mobile Paywall Shield Active</h3>
        <p className="text-[13px] text-slate-400 max-w-[560px] leading-relaxed mb-4">
          When a Free user hits their daily limit of <strong>{config.free_daily_posts_limit} AI post generations</strong> or <strong>{config.free_monthly_watchlist_limit} competitor research</strong> queries, the backend will automatically intercept and return a paywall block status, triggering the subscription purchase popup in the Flutter mobile client.
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
