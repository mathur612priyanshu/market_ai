const SystemConfig = require('../models/SystemConfig');
const User = require('../models/User');
const RechargeHistory = require('../models/RechargeHistory');
const Razorpay = require('razorpay');
const crypto = require('crypto');

// Helper to get configuration key values
async function getConfigValues() {
  const configs = await SystemConfig.findAll();
  const map = {};
  configs.forEach(c => {
    map[c.key] = c.value;
  });
  
  // Return fallback defaults if configs are not seeded yet
  return {
    base_day_price: Number(map.base_day_price || 50.0),
    discount_1_month: Number(map.discount_1_month || 10),
    discount_3_months: Number(map.discount_3_months || 20),
    discount_6_months: Number(map.discount_6_months || 30),
    discount_12_months: Number(map.discount_12_months || 40),
    free_daily_posts_limit: Number(map.free_daily_posts_limit || 3),
    free_monthly_watchlist_limit: Number(map.free_monthly_watchlist_limit || 5),
    gemini_cost: Number(map.gemini_cost || 0.035),
    apify_cost: Number(map.apify_cost || 0.12),
    meta_cost: Number(map.meta_cost || 0.005),
    gemini_limit: Number(map.gemini_limit || 300)
  };
}

// Endpoint: GET /api/plans/rates
// Public endpoint to get subscription plan structures and calculated pricing packages
exports.getPlansRates = async (req, res) => {
  try {
    const config = await getConfigValues();
    const basePrice = config.base_day_price;

    const packages = [
      {
        id: '1_month',
        name: '1 Month Membership',
        days: 30,
        discountPercent: config.discount_1_month,
        originalPrice: Math.round(30 * basePrice),
        finalPrice: Math.round(30 * basePrice * (1 - config.discount_1_month / 100))
      },
      {
        id: '3_months',
        name: 'Quarterly Pass (3 Months)',
        days: 90,
        discountPercent: config.discount_3_months,
        originalPrice: Math.round(90 * basePrice),
        finalPrice: Math.round(90 * basePrice * (1 - config.discount_3_months / 100))
      },
      {
        id: '6_months',
        name: 'Semi-Annual Plan (6 Months)',
        days: 180,
        discountPercent: config.discount_6_months,
        originalPrice: Math.round(180 * basePrice),
        finalPrice: Math.round(180 * basePrice * (1 - config.discount_6_months / 100))
      },
      {
        id: '12_months',
        name: 'Annual Agency Plan (12 Months)',
        days: 365,
        discountPercent: config.discount_12_months,
        originalPrice: Math.round(365 * basePrice),
        finalPrice: Math.round(365 * basePrice * (1 - config.discount_12_months / 100))
      }
    ];

    return res.status(200).json({
      success: true,
      baseDayPrice: basePrice,
      packages
    });
  } catch (error) {
    console.error('Error fetching plan packages:', error.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// Endpoint: POST /api/plans/subscribe
// Protected endpoint for client/user purchase renewals
exports.subscribeUser = async (req, res) => {
  try {
    const userId = req.user.id;
    const { packageId, days } = req.body;

    const config = await getConfigValues();
    const basePrice = config.base_day_price;

    let durationDays = 0;
    let discountPercent = 0;
    let planName = 'Custom Duration Plan';

    if (packageId) {
      if (packageId === '1_month') {
        durationDays = 30;
        discountPercent = config.discount_1_month;
        planName = '1 Month Membership';
      } else if (packageId === '3_months') {
        durationDays = 90;
        discountPercent = config.discount_3_months;
        planName = 'Quarterly Pass (3 Months)';
      } else if (packageId === '6_months') {
        durationDays = 180;
        discountPercent = config.discount_6_months;
        planName = 'Semi-Annual Plan (6 Months)';
      } else if (packageId === '12_months') {
        durationDays = 365;
        discountPercent = config.discount_12_months;
        planName = 'Annual Agency Plan (12 Months)';
      } else {
        return res.status(400).json({ success: false, error: 'Invalid Package ID' });
      }
    } else if (days) {
      durationDays = parseInt(days);
      if (isNaN(durationDays) || durationDays <= 0) {
        return res.status(400).json({ success: false, error: 'Invalid days count' });
      }
      planName = `${durationDays} Days Pass`;
    } else {
      return res.status(400).json({ success: false, error: 'packageId or days parameter is required' });
    }

    // Calculate final billing amount
    const originalPrice = durationDays * basePrice;
    const finalPrice = Math.round(originalPrice * (1 - discountPercent / 100));

    // Retrieve active User account
    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User profile not found' });
    }

    // Extend subscription expiration date safely
    let currentExpiration = null;
    if (user.subscriptionExpiresAt) {
      const parsedDate = new Date(user.subscriptionExpiresAt);
      if (!isNaN(parsedDate.getTime())) {
        currentExpiration = parsedDate;
      }
    }
    const now = new Date();

    let newExpiration;
    if (!currentExpiration || currentExpiration < now) {
      // If plan has expired or never subscribed, set expiration to now + days
      newExpiration = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);
    } else {
      // If plan is currently active, extend it by days relative to the existing end date
      newExpiration = new Date(currentExpiration.getTime() + durationDays * 24 * 60 * 60 * 1000);
    }

    if (isNaN(newExpiration.getTime())) {
      newExpiration = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);
    }

    // Update User model columns
    user.plan = 'Pro';
    user.subscriptionExpiresAt = newExpiration;
    user.subscriptionDaysPurchased = (user.subscriptionDaysPurchased || 0) + durationDays;
    user.subscriptionActivatedAt = user.subscriptionActivatedAt || now;
    await user.save();

    // Create record in RechargeHistory table
    const transactionId = 'TXN_RAZOR_' + Date.now() + Math.round(Math.random() * 1000);
    const recharge = await RechargeHistory.create({
      userId,
      planName,
      amount: finalPrice,
      days: durationDays,
      status: 'completed',
      paymentGateway: 'Razorpay',
      transactionId
    });

    return res.status(200).json({
      success: true,
      message: 'Subscription purchased/renewed successfully!',
      plan: user.plan,
      subscriptionExpiresAt: user.subscriptionExpiresAt,
      recharge
    });

  } catch (error) {
    console.error('Error renewing user subscription:', error.message);
    return res.status(500).json({ success: false, error: 'Internal Server Error' });
  }
};

// Endpoint: GET /api/admin/plans/config
// Protected admin endpoint to fetch system pricing setups
exports.getPlansConfig = async (req, res) => {
  try {
    const config = await getConfigValues();
    return res.status(200).json({ success: true, config });
  } catch (error) {
    console.error('Error fetching admin plans config:', error.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// Endpoint: POST /api/admin/plans/config
// Protected admin endpoint to update system pricing setups
exports.updatePlansConfig = async (req, res) => {
  try {
    const settings = req.body;
    
    for (const key of Object.keys(settings)) {
      await SystemConfig.upsert({
        key,
        value: String(settings[key])
      });
    }

    const config = await getConfigValues();
    return res.status(200).json({
      success: true,
      message: 'System plan parameters updated successfully!',
      config
    });
  } catch (error) {
    console.error('Error updating admin plans config:', error.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// Endpoint: POST /api/plans/razorpay/create-order
// Protected endpoint to generate a Razorpay order
exports.createRazorpayOrder = async (req, res) => {
  const { packageId } = req.body;
  if (!packageId) {
    return res.status(400).json({ success: false, error: 'packageId is required' });
  }

  try {
    const key_id = process.env.RAZORPAY_KEY_ID;
    const key_secret = process.env.RAZORPAY_KEY_SECRET;

    if (!key_id || !key_secret) {
      return res.status(500).json({ success: false, error: 'Razorpay keys are not configured on the server.' });
    }

    // 1. Get packages list and calculate price dynamically
    const config = await getConfigValues();
    const baseDayPrice = config.base_day_price;

    let days = 30;
    let discount = 0;
    let planName = 'Monthly Pass (1 Month)';

    if (packageId === '1_month') {
      days = 30;
      discount = config.discount_1_month;
      planName = 'Monthly Pass (1 Month)';
    } else if (packageId === '3_months') {
      days = 90;
      discount = config.discount_3_months;
      planName = 'Quarterly Pass (3 Months)';
    } else if (packageId === '6_months') {
      days = 180;
      discount = config.discount_6_months;
      planName = 'Half-Yearly Pass (6 Months)';
    } else if (packageId === '12_months') {
      days = 365;
      discount = config.discount_12_months;
      planName = 'Annual Pass (1 Year)';
    } else {
      return res.status(400).json({ success: false, error: 'Invalid packageId selected' });
    }

    const originalPrice = days * baseDayPrice;
    const finalPrice = Math.round(originalPrice * (1 - discount / 100));

    // 2. Initialize Razorpay SDK instance
    const razorpay = new Razorpay({
      key_id,
      key_secret
    });

    // 3. Create Order
    const options = {
      amount: finalPrice * 100, // Razorpay amount is in paise (₹1 = 100 paise)
      currency: 'INR',
      receipt: `rcpt_plan_${Date.now()}`
    };

    const order = await razorpay.orders.create(options);

    return res.status(200).json({
      success: true,
      keyId: key_id,
      orderId: order.id,
      amount: finalPrice,
      days,
      planName
    });

  } catch (error) {
    console.error('Error creating Razorpay order:', error.message);
    return res.status(500).json({ success: false, error: 'Failed to create payment order: ' + error.message });
  }
};

// Endpoint: POST /api/plans/razorpay/verify-payment
// Protected endpoint to verify payment signature and activate subscription
exports.verifyRazorpayPayment = async (req, res) => {
  const { razorpay_order_id, razorpay_payment_id, razorpay_signature, packageId } = req.body;

  if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature || !packageId) {
    return res.status(400).json({ success: false, error: 'Missing payment signature parameters or packageId' });
  }

  try {
    const key_secret = process.env.RAZORPAY_KEY_SECRET;
    if (!key_secret) {
      return res.status(500).json({ success: false, error: 'Razorpay keys not configured on server.' });
    }

    // 1. Verify Signature
    const expectedSignature = crypto
      .createHmac('sha256', key_secret)
      .update(razorpay_order_id + '|' + razorpay_payment_id)
      .digest('hex');

    if (expectedSignature !== razorpay_signature) {
      return res.status(400).json({ success: false, error: 'Payment signature verification failed. Invalid transaction.' });
    }

    // 2. Compute subscription packages values
    const config = await getConfigValues();
    const baseDayPrice = config.base_day_price;

    let days = 30;
    let discount = 0;
    let planName = 'Monthly Pass (1 Month)';

    if (packageId === '1_month') {
      days = 30;
      discount = config.discount_1_month;
      planName = 'Monthly Pass (1 Month)';
    } else if (packageId === '3_months') {
      days = 90;
      discount = config.discount_3_months;
      planName = 'Quarterly Pass (3 Months)';
    } else if (packageId === '6_months') {
      days = 180;
      discount = config.discount_6_months;
      planName = 'Half-Yearly Pass (6 Months)';
    } else if (packageId === '12_months') {
      days = 365;
      discount = config.discount_12_months;
      planName = 'Annual Pass (1 Year)';
    }

    const originalPrice = days * baseDayPrice;
    const finalPrice = Math.round(originalPrice * (1 - discount / 100));

    // 3. Update User's subscription duration in database
    const userId = req.user.id;
    const user = await User.findByPk(userId);

    if (!user) {
      return res.status(404).json({ success: false, error: 'User account not found' });
    }

    const now = new Date();
    let currentExpiration = null;
    if (user.subscriptionExpiresAt) {
      const parsedDate = new Date(user.subscriptionExpiresAt);
      if (!isNaN(parsedDate.getTime())) {
        currentExpiration = parsedDate;
      }
    }
    let newExpiration;

    if (!currentExpiration || currentExpiration < now) {
      newExpiration = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
    } else {
      newExpiration = new Date(currentExpiration.getTime() + days * 24 * 60 * 60 * 1000);
    }

    if (isNaN(newExpiration.getTime())) {
      newExpiration = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
    }

    user.plan = 'Pro';
    user.subscriptionExpiresAt = newExpiration;
    user.subscriptionDaysPurchased = (user.subscriptionDaysPurchased || 0) + days;
    user.subscriptionActivatedAt = user.subscriptionActivatedAt || now;
    await user.save();

    // 4. Log transaction audit history
    const history = await RechargeHistory.create({
      userId,
      planName,
      amount: finalPrice,
      days,
      status: 'completed',
      paymentGateway: 'Razorpay',
      transactionId: razorpay_payment_id
    });

    console.log(`[Razorpay Payment Success] RechargeHistory ID: ${history.id}, User ID: ${userId}, Amount: ₹${finalPrice}`);

    return res.status(200).json({
      success: true,
      message: 'Payment verified and plan upgraded successfully!',
      subscriptionExpiresAt: user.subscriptionExpiresAt,
      plan: user.plan
    });

  } catch (error) {
    console.error('Error verifying payment:', error.message);
    return res.status(500).json({ success: false, error: 'Payment verification failed: ' + error.message });
  }
};
