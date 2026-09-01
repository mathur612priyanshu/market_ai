const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const authMiddleware = require('../middleware/authMiddleware');

router.post('/login', adminController.login);
router.get('/me', authMiddleware, adminController.me);

// Users management endpoints
router.get('/users', authMiddleware, adminController.getUsers);
router.put('/users/:id/plan', authMiddleware, adminController.updateUserPlan);

// Posts history endpoints
router.get('/posts', authMiddleware, adminController.getPosts);

// Usage stats endpoints
router.get('/usage', authMiddleware, adminController.getUsageStats);

// Dashboard dynamic aggregated KPIs
router.get('/dashboard-summary', authMiddleware, adminController.getDashboardSummary);

module.exports = router;
