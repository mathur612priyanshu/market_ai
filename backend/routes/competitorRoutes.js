const express = require('express');
const router = express.Router();
const competitorController = require('../controllers/competitorController');
const authMiddleware = require('../middleware/authMiddleware');

// Route for competitor analysis (Protected)
router.post('/analyze', authMiddleware, competitorController.analyzeCompetitors);

// Route for general AI Search (Protected)
router.post('/search', authMiddleware, competitorController.aiSearch);

module.exports = router;
