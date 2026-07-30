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

// Route for getting current user profile (Protected)
router.get('/me', authMiddleware, authController.getCurrentUser);

// Route for uploading profile photo (Protected, Multipart)
router.post('/upload-avatar', authMiddleware, uploadMiddleware.single('avatar'), authController.uploadAvatar);

// Route for updating business details (Protected)
router.post('/update-business', authMiddleware, authController.updateBusinessProfile);

// Route for uploading business logo (Protected, Multipart)
router.post('/upload-logo', authMiddleware, uploadMiddleware.single('logo'), authController.uploadLogo);

// Routes for Facebook/Instagram OAuth Integration
router.get('/facebook', socialController.initiateFacebook);
router.get('/facebook/callback', socialController.facebookCallback);
router.get('/social-status', authMiddleware, socialController.getSocialStatus);
router.post('/facebook/create-page', authMiddleware, socialController.createFacebookPage);
router.get('/facebook/categories', authMiddleware, socialController.getFacebookCategories);

module.exports = router;
