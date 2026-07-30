const express = require('express');
const router = express.Router();
const competitorController = require('../controllers/competitorController');
const authMiddleware = require('../middleware/authMiddleware');

// Route for competitor analysis (Protected)
router.post('/analyze', authMiddleware, competitorController.analyzeCompetitors);

module.exports = router;
