const express = require('express');
const cors = require('cors');
const path = require('path');
const sequelize = require('./config/db');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '.env') });

const app = express();
const PORT = process.env.PORT || 5000;

// Import Routes
const authRoutes = require('./routes/authRoutes');
const postRoutes = require('./routes/postRoutes');
const competitorRoutes = require('./routes/competitorRoutes');
const adRoutes = require('./routes/adRoutes');
const reportRoutes = require('./routes/reportRoutes');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Serve uploads folder as static files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Mount Routes
app.use('/api/auth', authRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/competitor', competitorRoutes);
app.use('/api/ads', adRoutes);
app.use('/api/reports', reportRoutes);

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
