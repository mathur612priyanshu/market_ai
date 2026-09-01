import React, { useState } from 'react';
import { Lock, Mail, Layers, Loader2 } from 'lucide-react';
import { API_BASE_URL } from '../config';

export default function Login({ onLoginSuccess }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email || !password) {
      setError('Please fill in all fields');
      return;
    }

    setError('');
    setLoading(true);

    try {
      const response = await fetch(`${API_BASE_URL}/api/admin/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });

      const data = await response.json();
      
      if (!response.ok || !data.success) {
        throw new Error(data.message || 'Login failed');
      }

      // Success
      localStorage.setItem('admin_token', data.token);
      localStorage.setItem('admin_user', JSON.stringify(data.admin));
      onLoginSuccess(data.token, data.admin);
    } catch (err) {
      console.error('Login error:', err.message);
      setError(err.message || 'Connection to server failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen w-screen flex items-center justify-center bg-dark-primary font-sans p-4">
      <div className="w-full max-w-[400px] p-8 rounded-2xl bg-dark-secondary border border-white/5 shadow-lg shadow-glow flex flex-col">
        {/* Header Logo */}
        <div className="mb-8 flex flex-col items-center gap-2 text-center">
          <div className="w-12 h-12 rounded-full bg-accent-purple/10 text-accent-purple flex items-center justify-center">
            <Layers size={24} />
          </div>
          <h1 className="font-display text-2xl font-extrabold bg-gradient-to-r from-accent-purple to-accent-cyan bg-clip-text text-transparent">
            MarketAI Portal
          </h1>
          <p className="text-xs text-slate-500">Log in to manage configurations and monitor metrics</p>
        </div>

        {error && (
          <div className="p-3.5 rounded-xl bg-accent-pink/12 border border-accent-pink/15 text-accent-pink text-[12px] font-semibold mb-5 leading-normal">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <label className="text-[11.5px] font-semibold text-slate-400">Email Address</label>
            <div className="relative">
              <Mail size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
              <input
                type="email"
                className="w-full pl-10 pr-4 py-3 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-sm outline-none focus:border-accent-purple focus:shadow-[0_0_10px_rgba(157,78,221,0.2)] transition-all"
                placeholder="admin@marketai.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={loading}
              />
            </div>
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-[11.5px] font-semibold text-slate-400">Password</label>
            <div className="relative">
              <Lock size={16} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
              <input
                type="password"
                className="w-full pl-10 pr-4 py-3 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-sm outline-none focus:border-accent-purple focus:shadow-[0_0_10px_rgba(157,78,221,0.2)] transition-all"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={loading}
              />
            </div>
          </div>

          <button
            type="submit"
            className="w-full py-3 mt-3 rounded-xl bg-gradient-to-r from-accent-purple to-accent-indigo text-slate-100 text-sm font-bold hover:brightness-110 active:brightness-95 transition shadow-glow flex justify-center items-center gap-2 cursor-pointer disabled:opacity-50"
            disabled={loading}
          >
            {loading ? (
              <>
                <Loader2 size={16} className="animate-spin" />
                <span>Logging in...</span>
              </>
            ) : (
              <span>Sign In</span>
            )}
          </button>
        </form>
      </div>
    </div>
  );
}
