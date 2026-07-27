const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');
const authMiddleware = require('../middleware/authMiddleware');

// Route for generating AI post content (Protected)
router.post('/generate', authMiddleware, postController.generatePostContent);

// Route for publishing or scheduling a social post (Protected)
router.post('/schedule', authMiddleware, postController.publishOrSchedulePost);

module.exports = router;
