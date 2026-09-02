const express = require('express');
const cors = require('cors');
const path = require('path');
const sequelize = require('./config/db');

// Register models for Sequelize auto-sync
require('./models/CompetitorWatchlist');
require('./models/CompetitorAd');
require('./models/Admin');
require('./models/SystemConfig');
require('./models/RechargeHistory');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '.env') });

const axios = require('axios');
const ApiUsage = require('./models/ApiUsage');
const context = require('./services/contextService');

// Global Axios Interceptor to log Meta Graph API usage
axios.interceptors.response.use(
  async (response) => {
    try {
      const url = response.config.url || '';
      if (url.includes('graph.facebook.com')) {
        const userId = response.config.metadata?.userId || context.getStore() || null;
        const action = url.split('graph.facebook.com/')[1]?.split('?')[0] || 'graph_call';
        await ApiUsage.create({
          userId,
          service: 'meta',
          action: action.substring(0, 255),
          status: 'success'
        });
      }
    } catch (err) {
      console.error('[Axios Meta Interceptor Error]:', err.message);
    }
    return response;
  },
  async (error) => {
    try {
      const config = error.config;
      if (config && config.url && config.url.includes('graph.facebook.com')) {
        const userId = config.metadata?.userId || context.getStore() || null;
        const action = config.url.split('graph.facebook.com/')[1]?.split('?')[0] || 'graph_call';
        await ApiUsage.create({
          userId,
          service: 'meta',
          action: action.substring(0, 255),
          status: 'failed'
        });
      }
    } catch (err) {
      console.error('[Axios Meta Interceptor Error]:', err.message);
    }
    return Promise.reject(error);
  }
);

const app = express();
const PORT = process.env.PORT || 5000;

// Import Routes
const authRoutes = require('./routes/authRoutes');
const postRoutes = require('./routes/postRoutes');
const competitorRoutes = require('./routes/competitorRoutes');
const adRoutes = require('./routes/adRoutes');
const reportRoutes = require('./routes/reportRoutes');
const adminRoutes = require('./routes/adminRoutes');
const plansRoutes = require('./routes/plansRoutes');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Serve public and uploads folders as static files
app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Public Compliance & Legal Pages (Required for Meta App Review)
app.get('/privacy-policy', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'privacy-policy.html'));
});

app.get('/terms-of-service', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'terms-of-service.html'));
});

app.get('/data-deletion', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'data-deletion.html'));
});

// Mount Routes
app.use('/api/auth', authRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/competitor', competitorRoutes);
app.use('/api/ads', adRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/plans', plansRoutes);

// Standard Status Endpoint
app.get('/api/status', (req, res) => {
  res.json({
    status: 'success',
    message: 'Backend server is running',
    timestamp: new Date()
  });
});

// Test Database Connection and start server
async function startServer() {
  try {
    // Authenticate database connection
    console.log('Connecting to database...');
    await sequelize.authenticate();
    console.log('Database connection established successfully.');
    
    // Sync models
    await sequelize.sync(); 
    console.log('Database models synchronized.');

    // Seed default system configurations if missing
    const SystemConfig = require('./models/SystemConfig');
    const defaultConfigs = [
      { key: 'base_day_price', value: '50.0' },
      { key: 'discount_1_month', value: '10' },
      { key: 'discount_3_months', value: '20' },
      { key: 'discount_6_months', value: '30' },
      { key: 'discount_12_months', value: '40' },
      { key: 'free_daily_posts_limit', value: '3' },
      { key: 'free_monthly_watchlist_limit', value: '5' },
      { key: 'gemini_cost', value: '0.035' },
      { key: 'apify_cost', value: '0.12' },
      { key: 'meta_cost', value: '0.005' },
      { key: 'gemini_limit', value: '300' }
    ];

    for (const config of defaultConfigs) {
      await SystemConfig.findOrCreate({
        where: { key: config.key },
        defaults: { value: config.value }
      });
    }
    console.log('System configurations seeded successfully.');
    
    // Start background scheduled posts publisher
    const { startScheduler } = require('./services/scheduler');
    startScheduler();
    
  } catch (error) {
    console.error('Unable to connect to the database:', error.message);
    console.warn('Warning: Server started without active database connection.');
  }

  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT} in ${process.env.NODE_ENV || 'development'} mode.`);
  });
}

startServer();
