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
    
    // Sync models (automatically adding new columns/updating tables to match schema)
    await sequelize.sync({ alter: true }); 
    console.log('Database models synchronized.');
    
  } catch (error) {
    console.error('Unable to connect to the database:', error.message);
    console.warn('Warning: Server started without active database connection.');
  }

  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT} in ${process.env.NODE_ENV || 'development'} mode.`);
  });
}

startServer();
