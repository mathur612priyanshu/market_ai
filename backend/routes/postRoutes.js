const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');
const authMiddleware = require('../middleware/authMiddleware');
const quotaMiddleware = require('../middleware/quotaMiddleware');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure upload directory for post media
const uploadDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, 'post-media-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 50 * 1024 * 1024 } // 50MB limit to support video reels
});

// Route for generating AI post content (Protected)
router.post('/generate', authMiddleware, quotaMiddleware, postController.generatePostContent);

// Route for publishing or scheduling a social post (Protected)
router.post('/schedule', authMiddleware, postController.publishOrSchedulePost);

// Route for uploading custom post media (Protected)
router.post('/upload-media', authMiddleware, upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, error: 'No file uploaded.' });
  }
  const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
  return res.status(200).json({ success: true, url: fileUrl });
});

module.exports = router;
