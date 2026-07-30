const axios = require('axios');
const SocialAccount = require('../models/SocialAccount');

exports.createAdCampaign = async (req, res) => {
  const { adAccountId, campaignName, objective, budget, headline, primaryText, creativeUrl } = req.body;
  const userId = req.user.id;

  if (!adAccountId || !campaignName || !objective || !budget || !headline || !primaryText) {
    return res.status(400).json({ success: false, error: 'Missing required campaign setup parameters.' });
  }

  try {
    // 1. Fetch User Access Token (facebook_user)
    const userAccount = await SocialAccount.findOne({
      where: { userId, platform: 'facebook_user' }
    });

    if (!userAccount) {
      return res.status(400).json({
        success: false,
        error: 'No connected Facebook Profile token found. Please link/re-authenticate your Facebook account inside Social Connect first.'
      });
    }

    const userToken = userAccount.accessToken;

    // 2. Fetch User connected Facebook Page (needed for Ad Creative representation)
    const pageAccount = await SocialAccount.findOne({
      where: { userId, platform: 'facebook' }
    });

    if (!pageAccount) {
      return res.status(400).json({
        success: false,
        error: 'No linked Facebook Page found. Ads must represent a Facebook Page. Please link your account first.'
      });
    }

    const pageId = pageAccount.accountId;

    // Map User Objective to Meta Objectives
    // Meta v20.0 Objectives: OUTREACH, LEADS, SALES, ENGAGEMENT, LOCAL_AWARENESS, APP_PROMOTION, TRAFFIC
    let metaObjective = 'OUTREACH';
    const objLower = objective.toLowerCase();
    if (objLower.includes('lead')) {
      metaObjective = 'LEADS';
    } else if (objLower.includes('sale') || objLower.includes('conversion')) {
      metaObjective = 'SALES';
    } else if (objLower.includes('traffic') || objLower.includes('link')) {
      metaObjective = 'TRAFFIC';
    } else if (objLower.includes('engage')) {
      metaObjective = 'ENGAGEMENT';
    }

    console.log(`Creating campaign on account ${adAccountId} with objective ${metaObjective}...`);

    // Clean Ad Account ID to ensure act_ prefix
    let cleanAdAccountId = adAccountId.trim();
    if (!cleanAdAccountId.startsWith('act_')) {
      cleanAdAccountId = 'act_' + cleanAdAccountId;
    }

    // 3. STEP A: Create Campaign
    let campaignId;
    try {
      const campaignRes = await axios.post(
        `https://graph.facebook.com/v20.0/${cleanAdAccountId}/campaigns`,
        {
          name: campaignName,
          objective: metaObjective,
          buying_type: 'AUCTION',
          status: 'PAUSED'
        },
        { headers: { Authorization: `Bearer ${userToken}` } }
      );
      campaignId = campaignRes.data.id;
    } catch (err) {
      console.error('Error creating campaign:', err.response?.data || err.message);
      return res.status(400).json({
        success: false,
        error: `Meta Campaign Error: ${err.response?.data?.error?.message || err.message}`
      });
    }

    // 4. STEP B: Create Ad Set
    // We map budget to local currency subunits (Daily budget in cents/paisas -> multiplier of 100)
    const numericBudget = parseInt(budget.toString().replace(/[^0-9]/g, '')) || 500;
    const dailyBudgetSubunits = numericBudget * 100;

    let adsetId;
    try {
      const adsetRes = await axios.post(
        `https://graph.facebook.com/v20.0/${cleanAdAccountId}/adsets`,
        {
          campaign_id: campaignId,
          name: `${campaignName} Ad Set`,
          daily_budget: dailyBudgetSubunits,
          billing_event: 'IMPRESSIONS',
          optimization_goal: 'IMPRESSIONS', // IMPRESSIONS is safest optimization for sandbox/new accounts
          targeting: {
            geo_locations: { countries: ['IN'] },
            age_min: 18,
            age_max: 65
          },
          status: 'PAUSED'
        },
        { headers: { Authorization: `Bearer ${userToken}` } }
      );
      adsetId = adsetRes.data.id;
    } catch (err) {
      console.error('Error creating adset:', err.response?.data || err.message);
      return res.status(400).json({
        success: false,
        error: `Meta Ad Set Error: ${err.response?.data?.error?.message || err.message}`
      });
    }

    // 5. STEP C: Create Ad Creative
    let creativeId;
    try {
      const finalCreativeUrl = creativeUrl || 'https://images.unsplash.com/photo-1542744094-3a31f103e35f?w=600';
      
      const creativeRes = await axios.post(
        `https://graph.facebook.com/v20.0/${cleanAdAccountId}/adcreatives`,
        {
          name: `${campaignName} Creative`,
          object_story_spec: {
            page_id: pageId,
            link_data: {
              link: 'https://facebook.com/' + pageId,
              message: primaryText,
              name: headline,
              picture: finalCreativeUrl
            }
          }
        },
        { headers: { Authorization: `Bearer ${userToken}` } }
      );
      creativeId = creativeRes.data.id;
    } catch (err) {
      console.error('Error creating creative:', err.response?.data || err.message);
      return res.status(400).json({
        success: false,
        error: `Meta Creative Error: ${err.response?.data?.error?.message || err.message}`
      });
    }

    // 6. STEP D: Create Ad (Binds Creative to Ad Set)
    let adId;
    try {
      const adRes = await axios.post(
        `https://graph.facebook.com/v20.0/${cleanAdAccountId}/ads`,
        {
          name: `${campaignName} Ad`,
          adset_id: adsetId,
          creative: { creative_id: creativeId },
          status: 'PAUSED'
        },
        { headers: { Authorization: `Bearer ${userToken}` } }
      );
      adId = adRes.data.id;
    } catch (err) {
      console.error('Error creating ad:', err.response?.data || err.message);
      return res.status(400).json({
        success: false,
        error: `Meta Ad Creation Error: ${err.response?.data?.error?.message || err.message}`
      });
    }

    return res.status(200).json({
      success: true,
      campaignId,
      adsetId,
      creativeId,
      adId
    });

  } catch (err) {
    console.error('Ad Campaign flow exception:', err.message);
    return res.status(500).json({ success: false, error: 'Internal Server Error' });
  }
};
