const { Op } = require('sequelize');
const axios = require('axios');
const ScheduledPost = require('../models/ScheduledPost');
const SocialAccount = require('../models/SocialAccount');

const checkAndPublishScheduledPosts = async () => {
  try {
    const now = new Date();
    
    // 1. Fetch all pending posts where scheduled time has arrived or passed
    const pendingPosts = await ScheduledPost.findAll({
      where: {
        status: 'pending',
        scheduledTime: {
          [Op.lte]: now
        }
      }
    });

    if (pendingPosts.length === 0) return;

    console.log(`[Scheduler] Found ${pendingPosts.length} pending post(s) to publish at ${now.toISOString()}`);

    for (const post of pendingPosts) {
      try {
        const account = await SocialAccount.findOne({
          where: { userId: post.userId, platform: post.platform }
        });

        if (!account) {
          throw new Error(`No connected ${post.platform} account found for user ID ${post.userId}`);
        }

        const fullText = post.hashtags ? `${post.caption}\n\n${post.hashtags}` : post.caption;

        // 2. Call Meta Graph API depending on platform
        if (post.platform === 'facebook') {
          if (post.mediaUrl) {
            // Photo feed post
            await axios.post(`https://graph.facebook.com/v20.0/${account.accountId}/photos`, null, {
              params: {
                url: post.mediaUrl,
                message: fullText,
                access_token: account.accessToken
              }
            });
          } else {
            // Text feed post
            await axios.post(`https://graph.facebook.com/v20.0/${account.accountId}/feed`, null, {
              params: {
                message: fullText,
                access_token: account.accessToken
              }
            });
          }
        } else if (post.platform === 'instagram') {
          // Instagram Container Publishing (2 Steps)
          // Step A: Create media item container
          const containerRes = await axios.post(`https://graph.facebook.com/v20.0/${account.accountId}/media`, null, {
            params: {
              image_url: post.mediaUrl || 'https://images.unsplash.com/photo-1611162617213-7d7a39e9b1d7?w=600',
              caption: fullText,
              access_token: account.accessToken
            }
          });

          const containerId = containerRes.data.id;

          // Step B: Publish the container
          await axios.post(`https://graph.facebook.com/v20.0/${account.accountId}/media_publish`, null, {
            params: {
              creation_id: containerId,
              access_token: account.accessToken
            }
          });
        }

        // 3. Mark as published in database
        post.status = 'published';
        await post.save();
        console.log(`[Scheduler] Successfully published post ID ${post.id} to ${post.platform}`);

      } catch (postError) {
        const errorDetails = postError.response ? JSON.stringify(postError.response.data) : postError.message;
        console.error(`[Scheduler] Failed to publish post ID ${post.id}:`, errorDetails);
        
        post.status = 'failed';
        post.errorMessage = errorDetails;
        await post.save();
      }
    }
  } catch (error) {
    console.error('[Scheduler] Error in scheduler execution loop:', error.message);
  }
};

// Start the scheduler interval check
const startScheduler = () => {
  console.log('[Scheduler] Background publisher service started (interval: 60s)');
  // Execute database scan every 60 seconds
  setInterval(checkAndPublishScheduledPosts, 60000);
};

module.exports = { startScheduler };
