const axios = require('axios');
const sequelize = require('../config/db');
const SocialAccount = require('../models/SocialAccount');

async function triggerMetadataCall() {
  try {
    await sequelize.authenticate();
    console.log('Database connected.');

    // Find any connected Facebook page account with an access token
    const fbAccounts = await SocialAccount.findAll({
      where: { platform: 'facebook' }
    });

    if (fbAccounts.length === 0) {
      console.log('No Facebook accounts found in database. Please log in or provide a Page ID and Access Token.');
      process.exit(0);
    }

    console.log(`Found ${fbAccounts.length} Facebook account(s).`);

    for (const acc of fbAccounts) {
      console.log(`Testing with Page ID: ${acc.accountId}, Name: ${acc.accountName}`);
      try {
        // GET /{page-id}/subscribed_apps is the official pages_manage_metadata endpoint
        const res = await axios.get(`https://graph.facebook.com/v20.0/${acc.accountId}/subscribed_apps`, {
          params: {
            access_token: acc.accessToken
          }
        });
        console.log(`[SUCCESS] pages_manage_metadata call succeeded for ${acc.accountId}:`, res.data);
      } catch (err) {
        console.warn(`[WARN] Call for ${acc.accountId} returned:`, err.response?.data || err.message);
        
        // Fallback: Query page settings / metadata
        try {
          const res2 = await axios.get(`https://graph.facebook.com/v20.0/${acc.accountId}`, {
            params: {
              fields: 'id,name,about,emails,phone,website,category_list',
              access_token: acc.accessToken
            }
          });
          console.log(`[SUCCESS Fallback] Metadata fields call succeeded for ${acc.accountId}:`, res2.data);
        } catch (err2) {
          console.error(`[ERROR Fallback]`, err2.response?.data || err2.message);
        }
      }
    }

    console.log('Finished testing.');
    process.exit(0);
  } catch (error) {
    console.error('Fatal error:', error.message);
    process.exit(1);
  }
}

triggerMetadataCall();
