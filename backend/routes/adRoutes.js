const express = require('express');
const router = express.Router();
const adController = require('../controllers/adController');
const authMiddleware = require('../middleware/authMiddleware');

// Route for campaign creation (Protected)
router.post('/create-campaign', authMiddleware, adController.createAdCampaign);

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

module.exports = router;
