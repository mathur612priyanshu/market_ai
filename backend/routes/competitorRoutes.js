const express = require('express');
const router = express.Router();
const competitorController = require('../controllers/competitorController');
const authMiddleware = require('../middleware/authMiddleware');
const quotaMiddleware = require('../middleware/quotaMiddleware');

// Route for competitor analysis (Protected)
router.post('/analyze', authMiddleware, quotaMiddleware, competitorController.analyzeCompetitors);

// Route for general AI Search (Protected)
router.post('/search', authMiddleware, quotaMiddleware, competitorController.aiSearch);

module.exports = router;
