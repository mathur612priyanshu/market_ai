const express = require('express');
const router = express.Router();
const adController = require('../controllers/adController');
const authMiddleware = require('../middleware/authMiddleware');

// Route for campaign creation (Protected)
router.post('/create-campaign', authMiddleware, adController.createAdCampaign);

module.exports = router;
