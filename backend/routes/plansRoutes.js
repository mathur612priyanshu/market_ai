const express = require('express');
const router = express.Router();
const plansController = require('../controllers/plansController');
const authMiddleware = require('../middleware/authMiddleware');

// Client package rates (Public)
router.get('/rates', plansController.getPlansRates);

// Client subscription purchase/renewal (Protected)
router.post('/subscribe', authMiddleware, plansController.subscribeUser);

// Admin configuration endpoints (Protected)
router.get('/config', authMiddleware, plansController.getPlansConfig);
router.post('/config', authMiddleware, plansController.updatePlansConfig);

// Razorpay Integration Endpoints (Protected)
router.post('/razorpay/create-order', authMiddleware, plansController.createRazorpayOrder);
router.post('/razorpay/verify-payment', authMiddleware, plansController.verifyRazorpayPayment);

module.exports = router;
