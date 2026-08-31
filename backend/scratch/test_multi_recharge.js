const sequelize = require('../config/db');
const User = require('../models/User');
const RechargeHistory = require('../models/RechargeHistory');

async function testMultiRecharge() {
  try {
    console.log('--- STARTING MULTI RECHARGE INTEGRITY TEST ---');
    await sequelize.authenticate();

    // 1. Create a clean test user
    const phone = '9999912345';
    await User.destroy({ where: { phone } });
    await RechargeHistory.destroy({ where: { userId: 999999 } }); // clean fallback

    const user = await User.create({
      id: 999999,
      phone,
      name: 'Test MultiRecharge User',
      plan: 'Free',
      subscriptionExpiresAt: null
    });

    console.log(`Initial state: Plan = ${user.plan}, Expiry = ${user.subscriptionExpiresAt}`);

    // 2. Perform first recharge of 30 days
    console.log('\n--- FIRST RECHARGE: 30 DAYS ---');
    let now = new Date();
    let currentExpiration = user.subscriptionExpiresAt ? new Date(user.subscriptionExpiresAt) : null;
    let newExpiration;
    
    if (!currentExpiration || currentExpiration < now) {
      newExpiration = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    } else {
      newExpiration = new Date(currentExpiration.getTime() + 30 * 24 * 60 * 60 * 1000);
    }

    user.plan = 'Pro';
    user.subscriptionExpiresAt = newExpiration;
    user.subscriptionDaysPurchased = (user.subscriptionDaysPurchased || 0) + 30;
    user.subscriptionActivatedAt = user.subscriptionActivatedAt || now;
    await user.save();

    await RechargeHistory.create({
      userId: user.id,
      planName: 'Monthly Pass (1 Month)',
      amount: 100,
      days: 30,
      status: 'completed',
      paymentGateway: 'Razorpay',
      transactionId: 'TXN_TEST_1'
    });

    console.log(`State after first recharge: Plan = ${user.plan}, Expiry = ${user.subscriptionExpiresAt}`);

    // 3. Perform second recharge of 90 days (Quarterly)
    console.log('\n--- SECOND RECHARGE: 90 DAYS ---');
    currentExpiration = user.subscriptionExpiresAt ? new Date(user.subscriptionExpiresAt) : null;
    
    if (!currentExpiration || currentExpiration < now) {
      newExpiration = new Date(now.getTime() + 90 * 24 * 60 * 60 * 1000);
    } else {
      newExpiration = new Date(currentExpiration.getTime() + 90 * 24 * 60 * 60 * 1000);
    }

    user.plan = 'Pro';
    user.subscriptionExpiresAt = newExpiration;
    user.subscriptionDaysPurchased = (user.subscriptionDaysPurchased || 0) + 90;
    await user.save();

    await RechargeHistory.create({
      userId: user.id,
      planName: 'Quarterly Pass (3 Months)',
      amount: 250,
      days: 90,
      status: 'completed',
      paymentGateway: 'Razorpay',
      transactionId: 'TXN_TEST_2'
    });

    console.log(`State after second recharge: Plan = ${user.plan}, Expiry = ${user.subscriptionExpiresAt}`);

    // 4. Retrieve histories and print verification
    const histories = await RechargeHistory.findAll({ where: { userId: user.id } });
    console.log('\nRecharge Logs in DB:');
    histories.forEach(h => {
      console.log(` - TXN: ${h.transactionId}, Plan: ${h.planName}, Days: ${h.days}, Amount: ₹${h.amount}`);
    });

    // Clean up
    await RechargeHistory.destroy({ where: { userId: user.id } });
    await user.destroy();
    console.log('\nDatabase cleaned up.');
    console.log('--- TEST FINISHED ---');
    process.exit(0);

  } catch (error) {
    console.error('Test failed with error:', error);
    process.exit(1);
  }
}

testMultiRecharge();
