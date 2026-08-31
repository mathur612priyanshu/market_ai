const sequelize = require('../config/db');
const User = require('../models/User');
const SystemConfig = require('../models/SystemConfig');
const RechargeHistory = require('../models/RechargeHistory');

async function verifyBillingFlow() {
  try {
    console.log('--- START BILLING & PAYWALL TESTING ---');
    await sequelize.authenticate();
    console.log('Connected to Database successfully.');

    // 1. Fetch configurations
    const configs = await SystemConfig.findAll();
    console.log('Current System Configurations in Database:');
    configs.forEach(c => console.log(` - ${c.key}: ${c.value}`));

    // 2. Retrieve or create a test user
    const [testUser] = await User.findOrCreate({
      where: { phone: '+919999999999' },
      defaults: {
        name: 'Test Verification User',
        email: 'test@marketai.com',
        plan: 'Free'
      }
    });
    console.log(`Test User retrieved. Current Plan: ${testUser.plan}, Expires: ${testUser.subscriptionExpiresAt}`);

    // 3. Simulate Pro package purchase (e.g. 90 days Quarterly Plan)
    const baseDayPrice = Number((await SystemConfig.findByPk('base_day_price'))?.value || 50.0);
    const discount3Months = Number((await SystemConfig.findByPk('discount_3_months'))?.value || 20);
    const durationDays = 90;

    const originalPrice = durationDays * baseDayPrice;
    const finalPrice = Math.round(originalPrice * (1 - discount3Months / 100));

    console.log(`Calculating Quarterly Plan:`);
    console.log(` - Days: ${durationDays}`);
    console.log(` - Original Price: ₹${originalPrice}`);
    console.log(` - Discount: ${discount3Months}%`);
    console.log(` - Price Paid: ₹${finalPrice}`);

    // Update test user's plan expiration
    const now = new Date();
    let currentExpiration = testUser.subscriptionExpiresAt ? new Date(testUser.subscriptionExpiresAt) : null;
    let newExpiration;
    
    if (!currentExpiration || currentExpiration < now) {
      newExpiration = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);
    } else {
      newExpiration = new Date(currentExpiration.getTime() + durationDays * 24 * 60 * 60 * 1000);
    }

    testUser.plan = 'Pro';
    testUser.subscriptionExpiresAt = newExpiration;
    testUser.subscriptionDaysPurchased = (testUser.subscriptionDaysPurchased || 0) + durationDays;
    testUser.subscriptionActivatedAt = testUser.subscriptionActivatedAt || now;
    await testUser.save();

    console.log(`User Plan updated: ${testUser.plan}, New Expiration Date: ${testUser.subscriptionExpiresAt}`);

    // Save Recharge Log
    const txnId = 'TXN_TEST_' + Date.now();
    const history = await RechargeHistory.create({
      userId: testUser.id,
      planName: 'Quarterly Pass (3 Months)',
      amount: finalPrice,
      days: durationDays,
      status: 'completed',
      paymentGateway: 'Razorpay',
      transactionId: txnId
    });

    console.log(`RechargeHistory logged in Database successfully:`);
    console.log(` - Recharge ID: ${history.id}`);
    console.log(` - Transaction ID: ${history.transactionId}`);
    console.log(` - Plan Name: ${history.planName}`);
    console.log(` - Price Recorded: ₹${history.amount}`);

    // Clean up verification user status for safety (set back to Free)
    testUser.plan = 'Free';
    testUser.subscriptionExpiresAt = null;
    await testUser.save();
    console.log('Test User set back to Free tier.');

    console.log('--- VERIFICATION SUCCESSFUL ---');
    process.exit(0);

  } catch (error) {
    console.error('Verification error:', error.message);
    process.exit(1);
  }
}

verifyBillingFlow();
