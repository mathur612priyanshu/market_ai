import { useState, useEffect } from 'react';
import { Menu, Layers } from 'lucide-react';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import Usage from './pages/Usage';
import Plans from './pages/Plans';
import Login from './pages/Login';
import Posts from './pages/Posts';
import { API_BASE_URL } from './config';

function App() {
  const [activeTab, setActiveTab] = useState('overview');
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [token, setToken] = useState(localStorage.getItem('admin_token') || null);
  const [adminUser, setAdminUser] = useState(() => {
    try {
      const cached = localStorage.getItem('admin_user');
      return cached ? JSON.parse(cached) : null;
    } catch {
      return null;
    }
  });

  const handleLoginSuccess = (tok, usr) => {
    setToken(tok);
    setAdminUser(usr);
  };

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    setToken(null);
    setAdminUser(null);
  };

  const [users, setUsers] = useState([]);

  // Fetch users dynamically from the backend MySQL database
  const fetchUsers = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/admin/users`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      const data = await response.json();
      if (data.success && data.users) {
        setUsers(data.users);
      }
    } catch (error) {
      console.error('Error fetching users dynamically:', error.message);
    }
  };

  const [posts, setPosts] = useState([]);

  // Fetch posts dynamically from the backend MySQL database
  const fetchPosts = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/admin/posts`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      const data = await response.json();
      if (data.success && data.posts) {
        setPosts(data.posts);
      }
    } catch (error) {
      console.error('Error fetching posts dynamically:', error.message);
    }
  };

  const [usageStats, setUsageStats] = useState({
    geminiCalls: 0,
    apifyCrawls: 0,
    metaCalls: 0,
    integrations: {
      gemini: { status: 'disabled', label: 'Loading...' },
      apify: { status: 'disabled', label: 'Loading...' },
      meta: { status: 'disabled', label: 'Loading...' }
    }
  });

  const fetchUsageStats = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/admin/usage`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      const data = await response.json();
      if (data.success) {
        setUsageStats({
          geminiCalls: data.geminiCalls,
          apifyCrawls: data.apifyCrawls,
          metaCalls: data.metaCalls,
          integrations: data.integrations
        });
      }
    } catch (error) {
      console.error('Error fetching usage stats dynamically:', error.message);
    }
  };

  const fetchApiCosts = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/plans/config`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      const data = await response.json();
      if (data.success && data.config) {
        setApiCosts({
          geminiCost: String(data.config.gemini_cost !== undefined ? data.config.gemini_cost : '0.035'),
          apifyCost: String(data.config.apify_cost !== undefined ? data.config.apify_cost : '0.12'),
          metaCost: String(data.config.meta_cost !== undefined ? data.config.meta_cost : '0.005'),
          geminiLimit: String(data.config.gemini_limit !== undefined ? data.config.gemini_limit : '300')
        });
      }
    } catch (error) {
      console.error('Error fetching API cost configurations:', error.message);
    }
  };

  useEffect(() => {
    if (token) {
      fetchUsers();
      fetchPosts();
      fetchUsageStats();
      fetchApiCosts();
    }
  }, [token]);

  const [plans, setPlans] = useState([
    { id: 'free', name: 'Free Tier', price: 0, adsLimit: 3, spyLimit: 5, postsLimit: 5, leadsLimit: 50, active: true },
    { id: 'pro', name: 'Growth Pro', price: 29, adsLimit: 50, spyLimit: 100, postsLimit: 100, leadsLimit: 1000, active: true },
    { id: 'enterprise', name: 'Agency Enterprise', price: 99, adsLimit: 999, spyLimit: 999, postsLimit: 999, leadsLimit: 9999, active: true },
  ]);

  const [apiCosts, setApiCosts] = useState({
    geminiCost: '0.035', // average per generation
    apifyCost: '0.12',   // average per crawl
    metaCost: '0.005',   // average per request
    geminiLimit: '300',
    apifyLimit: '150',
  });

  // --- Handlers ---
  const handleUpdateUserPlan = async (userId, newPlan) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/admin/users/${userId}/plan`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ plan: newPlan })
      });
      const data = await response.json();
      if (data.success) {
        // Refresh the list immediately
        fetchUsers();
      } else {
        alert(data.message || 'Failed to update plan');
      }
    } catch (error) {
      console.error('Error updating user plan:', error.message);
      alert('Connection error');
    }
  };

  const handleUpdatePlanLimit = (planId, key, value) => {
    setPlans(plans.map(p => p.id === planId ? { ...p, [key]: Number(value) } : p));
  };

  const handleUpdateApiCost = (key, value) => {
    setApiCosts({ ...apiCosts, [key]: value });
  };

  const handleSaveApiCosts = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/plans/config`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          gemini_cost: apiCosts.geminiCost,
          apify_cost: apiCosts.apifyCost,
          meta_cost: apiCosts.metaCost,
          gemini_limit: apiCosts.geminiLimit
        })
      });
      const data = await response.json();
      if (data.success) {
        setApiCosts({
          geminiCost: String(data.config.gemini_cost),
          apifyCost: String(data.config.apify_cost),
          metaCost: String(data.config.meta_cost),
          geminiLimit: String(data.config.gemini_limit)
        });
        alert('API unit costs saved successfully to database!');
      } else {
        alert('Failed to save costs config: ' + data.error);
      }
    } catch (error) {
      console.error('Error saving API costs config:', error.message);
      alert('Network error. Failed to save.');
    }
  };

  if (!token) {
    return <Login onLoginSuccess={handleLoginSuccess} />;
  }

  return (
    <div className="flex flex-col md:flex-row w-screen h-screen overflow-hidden bg-dark-primary font-sans">
      {/* Mobile Top Navbar */}
      <div className="md:hidden flex justify-between items-center p-4 border-b border-white/5 bg-dark-secondary text-slate-100 flex-shrink-0">
        <button
          onClick={() => setIsSidebarOpen(true)}
          className="p-1 hover:bg-white/5 rounded-lg text-slate-300 hover:text-white transition cursor-pointer"
        >
          <Menu size={22} />
        </button>
        <div className="font-display font-bold text-base flex items-center gap-1.5 bg-gradient-to-r from-accent-purple to-accent-cyan bg-clip-text text-transparent">
          <Layers size={18} className="text-accent-purple" />
          <span>MarketAI Portal</span>
        </div>
        <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-accent-cyan to-accent-pink flex items-center justify-center font-display font-bold text-dark-primary text-xs">
          AD
        </div>
      </div>

      {/* Mobile Sidebar Backdrop Overlay */}
      {isSidebarOpen && (
        <div
          className="fixed inset-0 bg-black/60 z-40 md:hidden backdrop-blur-sm transition-all"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Sidebar Responsive Drawer */}
      <div className={`fixed inset-y-0 left-0 z-50 md:static md:flex transform transition-transform duration-300 md:translate-x-0 ${
        isSidebarOpen ? 'translate-x-0' : '-translate-x-full'
      }`}>
        <Sidebar
          activeTab={activeTab}
          setActiveTab={(tab) => {
            setActiveTab(tab);
            setIsSidebarOpen(false); // Auto close sidebar on mobile click
          }}
          onLogout={handleLogout}
        />
      </div>

      {/* Dynamic Main Panel viewports */}
      <main className="flex-1 h-full overflow-y-auto p-4 md:p-8 flex flex-col">
        {activeTab === 'overview' && (
          <Dashboard users={users} />
        )}
        {activeTab === 'users' && (
          <Users users={users} handleUpdateUserPlan={handleUpdateUserPlan} />
        )}
        {activeTab === 'posts' && (
          <Posts posts={posts} />
        )}
        {activeTab === 'usage' && (
          <Usage 
            apiCosts={apiCosts} 
            handleUpdateApiCost={handleUpdateApiCost} 
            handleSaveApiCosts={handleSaveApiCosts}
            usageStats={usageStats} 
          />
        )}
        {activeTab === 'plans' && (
          <Plans />
        )}
      </main>
    </div>
  );
}

export default App;
