import React, { useState } from 'react';
import {
  Search,
  Edit,
  X
} from 'lucide-react';

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

export default function Users({ users, handleUpdateUserPlan }) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedUserForEdit, setSelectedUserForEdit] = useState(null);

  const filteredUsers = users.filter(user =>
    user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    user.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
    user.plan.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="animate-fade-in flex flex-col gap-6">
      <header className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold font-display text-slate-100">Users Management</h1>
          <p className="text-[13.5px] text-slate-400">Manage, provision, and review active client subscriptions and social channel configurations.</p>
        </div>
      </header>

      <div className="p-6 rounded-2xl bg-dark-secondary border border-white/5">
        <div className="flex justify-between items-center mb-6">
          <div className="relative w-[280px]">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
            <input
              type="text"
              className="w-full pl-9 pr-4 py-2 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-xs outline-none focus:border-accent-purple focus:shadow-[0_0_10px_rgba(157,78,221,0.2)] transition-all"
              placeholder="Search users name, email, plan..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
        </div>

        <div className="w-full overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-white/5">
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">User ID</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Name</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Email Address</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Joined On</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Connected Channels</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Plan Type</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Total Ops Usage</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Account Status</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.map(user => (
                <tr key={user.id} className="border-b border-white/5 last:border-b-0 hover:bg-white/[0.01] transition-all">
                  <td className="p-4 text-[13px] font-bold text-slate-500">#{user.id}</td>
                  <td className="p-4 text-[13px] font-semibold text-slate-200">{user.name}</td>
                  <td className="p-4 text-[13px] text-slate-400">{user.email}</td>
                  <td className="p-4 text-[13px] text-slate-400">{user.joined}</td>
                  <td className="p-4">
                    <div className="flex gap-2 text-slate-400">
                      {user.platforms.includes('facebook') && <FacebookIcon size={16} />}
                      {user.platforms.includes('instagram') && <InstagramIcon size={16} />}
                      {user.platforms.length === 0 && <span className="text-slate-500 text-[11px]">None</span>}
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
                  <td className="p-4 text-[13px] font-semibold text-slate-300">{user.usage}</td>
                  <td className="p-4">
                    <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold ${
                      user.status === 'active' ? 'bg-accent-green/12 text-accent-green' : 'bg-accent-pink/12 text-accent-pink'
                    }`}>
                      {user.status}
                    </span>
                  </td>
                  <td className="p-4">
                    <button
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-white/5 bg-dark-tertiary hover:bg-white/5 text-[11.5px] font-semibold text-slate-300 hover:text-white transition"
                      onClick={() => setSelectedUserForEdit(user)}
                    >
                      <Edit size={12} />
                      <span>Change Plan</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Dialog for Changing User Plan */}
      {selectedUserForEdit && (
        <div className="fixed top-0 left-0 w-screen h-screen bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in">
          <div className="w-[400px] rounded-2xl p-6 bg-dark-secondary border border-white/10 flex flex-col shadow-lg">
            <div className="flex justify-between items-center mb-3">
              <h3 className="text-lg font-bold font-display text-slate-100">Modify User Subscription</h3>
              <X size={18} className="text-slate-500 hover:text-white cursor-pointer" onClick={() => setSelectedUserForEdit(null)} />
            </div>
            <p className="text-[13px] text-slate-400 mb-5 leading-relaxed">
              Choose the active subscription tier for <strong>{selectedUserForEdit.name}</strong>.
            </p>

            <div className="mb-5">
              <label className="block text-[12.5px] font-semibold text-slate-400 mb-2">Subscription Tier</label>
              <select
                className="w-full px-4 py-2.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-[13px] outline-none focus:border-accent-purple"
                value={selectedUserForEdit.plan}
                onChange={(e) => {
                  handleUpdateUserPlan(selectedUserForEdit.id, e.target.value);
                  setSelectedUserForEdit(null);
                }}
              >
                <option value="Free">Free Tier</option>
                <option value="Pro">Growth Pro</option>
                <option value="Enterprise">Agency Enterprise</option>
              </select>
            </div>

            <div className="flex gap-2.5 justify-end">
              <button className="px-4 py-2 rounded-xl text-xs font-bold bg-dark-tertiary border border-white/5 text-slate-300 hover:bg-white/5" onClick={() => setSelectedUserForEdit(null)}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
