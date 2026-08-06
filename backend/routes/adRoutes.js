const express = require('express');
const router = express.Router();
const adController = require('../controllers/adController');
const authMiddleware = require('../middleware/authMiddleware');

// Routes for split campaign creation wizard (Protected)
router.post('/campaigns/create', authMiddleware, adController.createCampaignOnly);
router.post('/adsets/create', authMiddleware, adController.createAdSetOnly);
router.post('/ads/create', authMiddleware, adController.createAdOnly);

// Route for listing campaigns (Protected)
router.get('/campaigns', authMiddleware, adController.listAdCampaigns);

// Route for toggling status (Protected)
router.post('/campaigns/status', authMiddleware, adController.toggleCampaignStatus);

// Route for duplicating campaign (Protected)
router.post('/campaigns/duplicate', authMiddleware, adController.duplicateCampaign);

// Route for editing campaign (Protected)
router.post('/campaigns/edit', authMiddleware, adController.editCampaign);

// Route for fetching campaign insights (Protected)
router.get('/campaigns/insights', authMiddleware, adController.getCampaignInsights);

// Route for dashboard aggregated insights (Protected)
router.get('/dashboard-stats', authMiddleware, adController.getDashboardStats);

// Route for listing user's ad accounts (Protected)
router.get('/accounts', authMiddleware, adController.listUserAdAccounts);

// Route for searching geolocation (Protected)
router.get('/search-geolocation', authMiddleware, adController.searchGeolocation);

// Route for fetching advertisable applications (Protected)
router.get('/accounts/:adAccountId/apps', authMiddleware, adController.getAdvertisableApps);

module.exports = router;
