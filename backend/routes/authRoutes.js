const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const socialController = require('../controllers/socialController');
const authMiddleware = require('../middleware/authMiddleware');
const uploadMiddleware = require('../middleware/uploadMiddleware');

// Route for sending OTP
router.post('/send-otp', authController.sendOtp);

// Route for verifying OTP (Login / Sign Up)
router.post('/verify-otp', authController.verifyOtp);

// Route for updating profile (Protected)
router.post('/update-profile', authMiddleware, authController.updateProfile);

// Route for uploading profile photo (Protected, Multipart)
router.post('/upload-avatar', authMiddleware, uploadMiddleware.single('avatar'), authController.uploadAvatar);

// Routes for Facebook/Instagram OAuth Integration
router.get('/facebook', socialController.initiateFacebook);
router.get('/facebook/callback', socialController.facebookCallback);
router.get('/social-status', authMiddleware, socialController.getSocialStatus);

module.exports = router;
