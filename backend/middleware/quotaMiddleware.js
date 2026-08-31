const { Op } = require('sequelize');
const User = require('../models/User');
const ScheduledPost = require('../models/ScheduledPost');
const CompetitorWatchlist = require('../models/CompetitorWatchlist');
const SystemConfig = require('../models/SystemConfig');

module.exports = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const user = await User.findByPk(userId);

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const now = new Date();

    // 1. If user is listed as Pro but subscription has expired, revert to Free
    if (user.plan === 'Pro' && user.subscriptionExpiresAt && new Date(user.subscriptionExpiresAt) < now) {
      console.log(`[Paywall] User ${user.id} subscription expired. Reverting to Free tier.`);
      user.plan = 'Free';
      await user.save();
    }

    // 2. If user is on Free tier, check quota limits
    if (user.plan === 'Free') {
      const ApiUsage = require('../models/ApiUsage');
      const path = req.path;

      // Case A: Post Generation Quota Check
      if (req.originalUrl.includes('/posts/generate')) {
        const dailyPostsLimitConfig = await SystemConfig.findByPk('free_daily_posts_limit');
        const dailyLimit = Number(dailyPostsLimitConfig?.value || 3);

        const twentyFourHoursAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        const postsGeneratedCount = await ApiUsage.count({
          where: {
            userId,
            service: 'gemini',
            action: 'post_generation',
            status: 'success',
            createdAt: {
              [Op.gt]: twentyFourHoursAgo
            }
          }
        });

        if (postsGeneratedCount >= dailyLimit) {
          return res.status(403).json({
            success: false,
            error: 'paywall_block',
            message: `You have reached your daily limit of ${dailyLimit} AI post generations on the Free plan. Upgrade to Pro for unlimited content generation!`
          });
        }
      }

      // Case B: Competitor Watchlist & AI Search Checks
      if (req.originalUrl.includes('/competitor/analyze') || req.originalUrl.includes('/competitor/search')) {
        const monthlyWatchlistLimitConfig = await SystemConfig.findByPk('free_monthly_watchlist_limit');
        const monthlyLimit = Number(monthlyWatchlistLimitConfig?.value || 5);

        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const researchCount = await ApiUsage.count({
          where: {
            userId,
            service: 'gemini',
            action: {
              [Op.or]: ['competitor_analysis', 'ai_search']
            },
            status: 'success',
            createdAt: {
              [Op.gt]: startOfMonth
            }
          }
        });

        if (researchCount >= monthlyLimit) {
          return res.status(403).json({
            success: false,
            error: 'paywall_block',
            message: `You have reached your monthly limit of ${monthlyLimit} competitor research queries on the Free plan. Upgrade to Pro for unlimited analysis!`
          });
        }
      }
    }

    // Pass verification check
    next();

  } catch (error) {
    console.error('[Paywall Quota Middleware Error]:', error.message);
    next(); // Pass through on backend system error to maintain user application usability
  }
};
