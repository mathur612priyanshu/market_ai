import React, { useState } from 'react';
import { Search, Eye, AlertCircle, Calendar, MessageSquare, Image, Tag, X } from 'lucide-react';

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

export default function Posts({ posts }) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedPost, setSelectedPost] = useState(null);

  const filteredPosts = posts.filter(post =>
    post.userName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    post.prompt.toLowerCase().includes(searchQuery.toLowerCase()) ||
    post.caption.toLowerCase().includes(searchQuery.toLowerCase()) ||
    post.status.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="animate-fade-in flex flex-col gap-6">
      <header className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold font-display text-slate-100">Posts & Generations History</h1>
          <p className="text-[13.5px] text-slate-400">Monitor user AI prompts, generated social captions, and publishing success metrics.</p>
        </div>
      </header>

      <div className="p-6 rounded-2xl bg-dark-secondary border border-white/5">
        <div className="flex justify-between items-center mb-6">
          <div className="relative w-[280px]">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
            <input
              type="text"
              className="w-full pl-9 pr-4 py-2 rounded-xl bg-dark-tertiary border border-white/5 text-slate-100 text-xs outline-none focus:border-accent-purple focus:shadow-[0_0_10px_rgba(157,78,221,0.2)] transition-all"
              placeholder="Search by user, prompt, status..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
        </div>

        <div className="w-full overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-white/5">
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Post ID</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">User Name</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Platform</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Original Prompt</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Tone & Type</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Status</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Date & Time</th>
                <th className="py-3.5 px-4 text-[11.5px] font-bold uppercase tracking-wider text-slate-400">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredPosts.length === 0 ? (
                <tr>
                  <td colSpan="8" className="p-8 text-center text-slate-500 text-sm">
                    No posts history recorded yet.
                  </td>
                </tr>
              ) : (
                filteredPosts.map(post => (
                  <tr key={post.id} className="border-b border-white/5 last:border-b-0 hover:bg-white/[0.01] transition-all">
                    <td className="p-4 text-[13px] font-bold text-slate-500">#{post.id}</td>
                    <td className="p-4">
                      <div className="flex flex-col">
                        <span className="text-[13px] font-semibold text-slate-200">{post.userName}</span>
                        <span className="text-[11px] text-slate-500">{post.userEmail}</span>
                      </div>
                    </td>
                    <td className="p-4 text-slate-300">
                      {post.platform === 'facebook' ? <FacebookIcon size={16} /> : <InstagramIcon size={16} />}
                    </td>
                    <td className="p-4 text-[13px] text-slate-300 max-w-[200px] truncate" title={post.prompt}>
                      {post.prompt}
                    </td>
                    <td className="p-4">
                      <div className="flex flex-wrap gap-1">
                        <span className="px-2 py-0.5 rounded bg-dark-tertiary border border-white/5 text-[10px] text-accent-indigo font-semibold">
                          {post.tone}
                        </span>
                        <span className="px-2 py-0.5 rounded bg-dark-tertiary border border-white/5 text-[10px] text-accent-cyan font-semibold">
                          {post.type}
                        </span>
                      </div>
                    </td>
                    <td className="p-4">
                      <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-semibold ${
                        post.status === 'published' ? 'bg-accent-green/12 text-accent-green' :
                        post.status === 'failed' ? 'bg-accent-pink/12 text-accent-pink' :
                        'bg-accent-orange/12 text-accent-orange'
                      }`}>
                        {post.status}
                      </span>
                    </td>
                    <td className="p-4 text-[12.5px] text-slate-400">
                      {post.scheduledTime ? new Date(post.scheduledTime).toLocaleString() : 'N/A'}
                    </td>
                    <td className="p-4">
                      <button
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-white/5 bg-dark-tertiary hover:bg-white/5 text-[11.5px] font-semibold text-slate-300 hover:text-white transition"
                        onClick={() => setSelectedPost(post)}
                      >
                        <Eye size={12} />
                        <span>Inspect Details</span>
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Inspect Post Details Modal Popup */}
      {selectedPost && (
        <div className="fixed top-0 left-0 w-screen h-screen bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in">
          <div className="w-[600px] max-h-[85vh] overflow-y-auto rounded-2xl p-6 bg-dark-secondary border border-white/10 flex flex-col shadow-lg">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-bold font-display text-slate-100 flex items-center gap-2">
                <MessageSquare size={18} className="text-accent-purple" />
                <span>API Generation Audit Details</span>
              </h3>
              <X size={18} className="text-slate-500 hover:text-white cursor-pointer" onClick={() => setSelectedPost(null)} />
            </div>

            <div className="flex flex-col gap-4 text-left">
              {/* Meta information row */}
              <div className="grid grid-cols-2 gap-4 p-3 rounded-xl bg-dark-tertiary border border-white/5 text-[12px]">
                <div className="flex flex-col gap-1 text-slate-400">
                  <span>Author: <strong className="text-slate-200">{selectedPost.userName}</strong></span>
                  <span>Email: <strong className="text-slate-200">{selectedPost.userEmail}</strong></span>
                </div>
                <div className="flex flex-col gap-1 text-slate-400">
                  <span>Platform: <strong className="text-slate-200 capitalize">{selectedPost.platform}</strong></span>
                  <span>Status: <strong className="text-slate-200 capitalize">{selectedPost.status}</strong></span>
                </div>
              </div>

              {/* original prompt */}
              <div>
                <label className="block text-[11.5px] font-semibold text-slate-500 mb-1">User Prompt Input</label>
                <div className="p-3.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-300 text-xs leading-relaxed font-mono">
                  {selectedPost.prompt}
                </div>
              </div>

              {/* generated caption */}
              <div>
                <label className="block text-[11.5px] font-semibold text-slate-500 mb-1">AI Generated Caption</label>
                <div className="p-3.5 rounded-xl bg-dark-tertiary border border-white/5 text-slate-200 text-xs leading-relaxed whitespace-pre-wrap">
                  {selectedPost.caption}
                </div>
              </div>

              {/* hashtags */}
              {selectedPost.hashtags && (
                <div>
                  <label className="block text-[11.5px] font-semibold text-slate-500 mb-1 flex items-center gap-1">
                    <Tag size={12} />
                    <span>Hashtags</span>
                  </label>
                  <div className="text-xs text-accent-cyan font-mono leading-relaxed">
                    {selectedPost.hashtags}
                  </div>
                </div>
              )}

              {/* Media preview */}
              {selectedPost.mediaUrl && (
                <div>
                  <label className="block text-[11.5px] font-semibold text-slate-500 mb-1.5 flex items-center gap-1">
                    <Image size={12} />
                    <span>Media Attachment Preview</span>
                  </label>
                  <div className="w-full h-[180px] rounded-xl overflow-hidden bg-dark-tertiary border border-white/5 flex items-center justify-center">
                    <img
                      src={selectedPost.mediaUrl}
                      alt="Attachment Preview"
                      className="w-full h-full object-contain"
                      onError={(e) => {
                        e.target.style.display = 'none';
                      }}
                    />
                  </div>
                </div>
              )}

              {/* error message details */}
              {selectedPost.status === 'failed' && selectedPost.errorMessage && (
                <div className="p-4 rounded-xl bg-accent-pink/10 border border-accent-pink/20 text-accent-pink text-[12px] flex gap-2.5 items-start">
                  <AlertCircle size={16} className="mt-0.5 flex-shrink-0" />
                  <div className="flex flex-col gap-1">
                    <span className="font-bold">Meta Graph API Error Logs:</span>
                    <span className="font-mono break-all leading-normal whitespace-pre-wrap">{selectedPost.errorMessage}</span>
                  </div>
                </div>
              )}
            </div>

            <div className="flex gap-2.5 justify-end mt-6 border-t border-white/5 pt-4">
              <button
                className="px-4.5 py-2 rounded-xl text-xs font-bold bg-dark-tertiary border border-white/5 text-slate-300 hover:bg-white/5"
                onClick={() => setSelectedPost(null)}
              >
                Close Audit Logs
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
