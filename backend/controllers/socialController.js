const axios = require('axios');
const SocialAccount = require('../models/SocialAccount');
const User = require('../models/User');

// Endpoint: GET /api/auth/facebook
// Initiates the OAuth redirect flow
exports.initiateFacebook = (req, res) => {
  const userId = req.query.userId || '1'; // ID of the user linking their social accounts
  const fbAppId = process.env.FB_APP_ID;
  const redirectUri = process.env.FB_REDIRECT_URI;

  if (!fbAppId || fbAppId === 'YOUR_FACEBOOK_APP_ID') {
    return res.status(500).send('Error: FB_APP_ID is not configured in environment variables');
  }

  const fbConfigId = process.env.FB_CONFIG_ID;

  if (!fbConfigId || fbConfigId === 'YOUR_CONFIG_ID_HERE') {
    return res.status(500).send('Error: FB_CONFIG_ID is not configured in environment variables');
  }

  // Redirect to Facebook OAuth with Business Configuration ID and required Ad scopes
  const oauthUrl = `https://www.facebook.com/v20.0/dialog/oauth?client_id=${fbAppId}&redirect_uri=${encodeURIComponent(redirectUri)}&config_id=${fbConfigId}&state=${userId}&scope=public_profile,pages_show_list,pages_read_engagement,pages_manage_metadata,pages_manage_posts,read_insights,instagram_basic,instagram_content_publish,instagram_manage_insights,ads_management,ads_read`;
  
  return res.redirect(oauthUrl);
};

// Endpoint: GET /api/auth/facebook/callback
// Callback handled by Facebook OAuth redirect
exports.facebookCallback = async (req, res) => {
  const { code, state: userId } = req.query;

  if (!code) {
    return res.status(400).send('Error: Authorization code not provided by Facebook');
  }

  const parsedUserId = parseInt(userId);
  if (isNaN(parsedUserId)) {
    return res.status(400).send(`
      <html>
        <body style="font-family: Arial, sans-serif; text-align: center; padding-top: 50px; background-color: #f7f9fc;">
          <h2 style="color: #FF5A5F;">Invalid Session ID</h2>
          <p>No valid user session was associated with this login. Please close this tab and retry.</p>
        </body>
      </html>
    `);
  }

  try {
    const userExists = await User.findByPk(parsedUserId);
    if (!userExists) {
      console.warn(`OAuth callback received invalid or non-existent userId: ${userId}`);
      return res.status(400).send(`
        <html>
          <body style="font-family: Arial, sans-serif; text-align: center; padding-top: 50px; background-color: #f7f9fc;">
            <div style="max-width: 500px; margin: 0 auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.05);">
              <div style="font-size: 50px; color: #FF5A5F; margin-bottom: 15px;">✕</div>
              <h2 style="color: #333; margin-bottom: 10px;">User Not Found</h2>
              <p style="color: #666; font-size: 14px; line-height: 1.5;">The user session in the app is not valid or has expired. Please log out of the mobile application and log in again, then retry connecting your social accounts.</p>
            </div>
          </body>
        </html>
      `);
    }
  } catch (dbErr) {
    console.error('Error validating user exists:', dbErr.message);
  }

  const fbAppId = process.env.FB_APP_ID;
  const fbAppSecret = process.env.FB_APP_SECRET;
  const redirectUri = process.env.FB_REDIRECT_URI;

  try {
    // 1. Exchange auth code for a short-lived user access token
    const tokenResponse = await axios.get('https://graph.facebook.com/v20.0/oauth/access_token', {
      params: {
        client_id: fbAppId,
        redirect_uri: redirectUri,
        client_secret: fbAppSecret,
        code: code
      }
    });

    const shortLivedToken = tokenResponse.data.access_token;

    // 2. Exchange short-lived token for a 60-day Long-Lived User Access Token
    const longLivedResponse = await axios.get('https://graph.facebook.com/v20.0/oauth/access_token', {
      params: {
        grant_type: 'fb_exchange_token',
        client_id: fbAppId,
        client_secret: fbAppSecret,
        fb_exchange_token: shortLivedToken
      }
    });

    const longLivedToken = longLivedResponse.data.access_token;

    // Save the User Access Token for Ad Campaign Management
    await SocialAccount.upsert({
      userId: parseInt(userId),
      platform: 'facebook_user',
      accountId: 'user_token_' + userId,
      accountName: 'Meta User Token',
      accessToken: longLivedToken
    });

    // 3. Fetch user's managed Facebook Pages (contains Page Access Tokens)
    const pagesResponse = await axios.get('https://graph.facebook.com/v20.0/me/accounts', {
      params: {
        access_token: longLivedToken
      }
    });

    const pages = pagesResponse.data.data; // List of managed Facebook pages

    if (!pages || pages.length === 0) {
      return res.status(200).send(`
        <html>
          <body style="font-family: Arial, sans-serif; text-align: center; padding-top: 50px; background-color: #f7f9fc;">
            <h2 style="color: #FF5A5F;">No Facebook Pages Found</h2>
            <p>You need to manage at least one Facebook Page to link social accounts.</p>
            <p>You can close this window now.</p>
          </body>
        </html>
      `);
    }

    // Process each Facebook page and search for linked Instagram Business accounts
    for (const page of pages) {
      // 4. Save/Update Facebook Page in SocialAccount database
      await SocialAccount.upsert({
        userId: parseInt(userId),
        platform: 'facebook',
        accountId: page.id,
        accountName: page.name,
        accessToken: page.access_token // Page token is permanent when obtained from a long-lived user token
      });

      // 5. Query if there is a linked Instagram Business Account
      try {
        const igResponse = await axios.get(`https://graph.facebook.com/v20.0/${page.id}`, {
          params: {
            fields: 'instagram_business_account',
            access_token: page.access_token
          }
        });

        const igAccount = igResponse.data.instagram_business_account;
        if (igAccount) {
          // 6. Fetch Instagram account username and profile details
          const igDetailsResponse = await axios.get(`https://graph.facebook.com/v20.0/${igAccount.id}`, {
            params: {
              fields: 'username,name,profile_picture_url',
              access_token: page.access_token
            }
          });

          const igDetails = igDetailsResponse.data;

          // 7. Save/Update Instagram Business Account in database
          await SocialAccount.upsert({
            userId: parseInt(userId),
            platform: 'instagram',
            accountId: igDetails.id,
            accountName: igDetails.username || igDetails.name,
            accessToken: page.access_token, // Publish calls to Instagram API are made using the linked Page Access Token
            profilePicture: igDetails.profile_picture_url
          });
        }
      } catch (igError) {
        // Log error but continue processing other pages (maybe this page has no IG account linked)
        console.warn(`Could not fetch Instagram account for Page ${page.name}:`, igError.message);
      }
    }

    // Return custom Success HTML template to browser
    return res.status(200).send(`
      <html>
        <body style="font-family: Arial, sans-serif; text-align: center; padding-top: 50px; background-color: #f7f9fc;">
          <div style="max-width: 500px; margin: 0 auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.05);">
            <div style="font-size: 50px; color: #4CAF50; margin-bottom: 15px;">✓</div>
            <h2 style="color: #333; margin-bottom: 10px;">Connection Successful!</h2>
            <p style="color: #666; font-size: 14px; line-height: 1.5;">Your Facebook Pages and linked Instagram accounts have been connected to MarketAI.</p>
            <p style="color: #999; font-size: 12px; margin-top: 30px;">You can now close this browser tab and return to the app.</p>
          </div>
        </body>
      </html>
    `);

  } catch (error) {
    const errorMsg = error.response?.data?.error?.message || error.message || '';
    const codeUsed = errorMsg.includes('authorization code has been used') || 
                     errorMsg.includes('code has been used') || 
                     errorMsg.includes('used');

    if (codeUsed) {
      try {
        const parsedUserId = parseInt(userId);
        const existingToken = await SocialAccount.findOne({
          where: { userId: parsedUserId, platform: 'facebook_user' }
        });
        if (existingToken) {
          console.log('Authorization code already exchanged in a previous request. Gracefully redirecting to success page.');
          return res.status(200).send(`
            <html>
              <body style="font-family: Arial, sans-serif; text-align: center; padding-top: 50px; background-color: #f7f9fc;">
                <div style="max-width: 500px; margin: 0 auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.05);">
                  <div style="font-size: 50px; color: #4CAF50; margin-bottom: 15px;">✓</div>
                  <h2 style="color: #333; margin-bottom: 10px;">Connection Successful!</h2>
                  <p style="color: #666; font-size: 14px; line-height: 1.5;">Your Facebook Pages and linked Instagram accounts have been connected to MarketAI.</p>
                  <p style="color: #999; font-size: 12px; margin-top: 30px;">You can now close this browser tab and return to the app.</p>
                </div>
              </body>
            </html>
          `);
        }
      } catch (dbErr) {
        console.error('Db lookup during codeUsed error handling failed:', dbErr.message);
      }
    }

    console.error('Error during Facebook OAuth Callback:', error.response ? error.response.data : error.message);
    return res.status(500).send(`
      <html>
        <body style="font-family: Arial, sans-serif; text-align: center; padding-top: 50px; background-color: #f7f9fc;">
          <div style="max-width: 500px; margin: 0 auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.05);">
            <div style="font-size: 50px; color: #FF5A5F; margin-bottom: 15px;">✕</div>
            <h2 style="color: #333; margin-bottom: 10px;">Authentication Failed</h2>
            <p style="color: #666; font-size: 14px; line-height: 1.5;">We encountered an error during the authentication flow. Please try again.</p>
            <p style="color: #999; font-size: 12px; margin-top: 30px;">Error Details: ${error.message}</p>
          </div>
        </body>
      </html>
    `);
  }
};

// Endpoint: GET /api/auth/social-status
// Returns the connection status of the user's social accounts
exports.getSocialStatus = async (req, res) => {
  const userId = req.user.id;
  try {
    const accounts = await SocialAccount.findAll({ where: { userId } });
    const facebookConnected = accounts.some(acc => acc.platform === 'facebook');
    const instagramConnected = accounts.some(acc => acc.platform === 'instagram');

    return res.status(200).json({
      success: true,
      facebookConnected,
      instagramConnected,
      accounts: accounts
        .filter(acc => acc.platform !== 'facebook_user')
        .map(acc => ({
          platform: acc.platform,
          accountId: acc.accountId,
          accountName: acc.accountName,
          profilePicture: acc.profilePicture
        }))
    });
  } catch (error) {
    console.error('Error fetching social status:', error.message);
    return res.status(500).json({ success: false, error: error.message });
  }
};

// Endpoint: POST /api/auth/facebook/create-page
// Creates a new Facebook Page programmatically under the logged-in user profile
exports.createFacebookPage = async (req, res) => {
  const userId = req.user.id;
  const { name, categoryId, about } = req.body;

  if (!name || !categoryId) {
    return res.status(400).json({ success: false, error: 'Page name and categoryId are required' });
  }

  try {
    // 1. Fetch User Access Token (facebook_user)
    const userAccount = await SocialAccount.findOne({
      where: { userId, platform: 'facebook_user' }
    });

    if (!userAccount) {
      return res.status(400).json({
        success: false,
        error: 'No connected Facebook Profile found. Please connect your Facebook account in Social Connect first.'
      });
    }

    const userToken = userAccount.accessToken;

    console.log(`Creating page "${name}" with categoryId "${categoryId}"...`);

    // 2. POST to /me/accounts
    const createRes = await axios.post(
      'https://graph.facebook.com/v20.0/me/accounts',
      {
        name,
        category_list: [
          categoryId
        ],
        about: about || 'Business page created via MarketAI'
      },
      {
        headers: {
          Authorization: `Bearer ${userToken}`
        }
      }
    );

    const newPageId = createRes.data.id;
    const newPageToken = createRes.data.access_token;

    if (!newPageId || !newPageToken) {
      return res.status(500).json({ success: false, error: 'Facebook API failed to return page details.' });
    }

    // 3. Upsert the new page directly to SocialAccount database so they can post to it immediately!
    await SocialAccount.upsert({
      userId: parseInt(userId),
      platform: 'facebook',
      accountId: newPageId,
      accountName: name,
      accessToken: newPageToken
    });

    return res.status(200).json({
      success: true,
      pageId: newPageId,
      pageName: name
    });

  } catch (error) {
    console.error('Error programmatically creating Facebook page:', error.response?.data || error.message);
    return res.status(400).json({
      success: false,
      error: error.response?.data?.error?.message || error.message
    });
  }
};

// Endpoint: GET /api/auth/facebook/categories
// Fetches the real page categories list from Meta Graph API
exports.getFacebookCategories = async (req, res) => {
  const userId = req.user.id;
  const { q } = req.query;

  try {
    const userAccount = await SocialAccount.findOne({
      where: { userId, platform: 'facebook_user' }
    });

    if (!userAccount) {
      return res.status(400).json({
        success: false,
        error: 'No connected Facebook Profile found.'
      });
    }

    const userToken = userAccount.accessToken;

    // Build API Params (Pass 'q' if user typed something)
    const apiParams = {
      access_token: userToken
    };
    if (q) {
      apiParams.q = q; // <--- TEEL FIX: Meta API ko search term bhej rahe hain
    }

    // Fetch live search results directly from Meta
    const fbRes = await axios.get('https://graph.facebook.com/v20.0/fb_page_categories', {
      params: apiParams
    });
    console.log('Fetched Facebook categories from Meta API:', fbRes.data.data, 'categories');

    const categories = (fbRes.data.data || []).map(cat => ({
      id: cat.id,
      name: cat.name,
      apiEnum: cat.api_enum || cat.name.toUpperCase().replace(/[^A-Z0-9]/g, '_')
    }));

    return res.status(200).json({
      success: true,
      categories
    });

  } catch (error) {
    console.error('Error fetching Facebook categories:', error.response?.data || error.message);
    
    // Fallback static list if Meta API fails or token expires
    const fallbackCategories = [
      { id: '1', name: 'Advertising/Marketing', apiEnum: 'ADVERTISING_MARKETING' },
      { id: '2', name: 'Business Services', apiEnum: 'BUSINESS_SERVICES' },
      { id: '3', name: 'Gym/Physical Fitness Center', apiEnum: 'GYM_PHYSICAL_FITNESS_CENTER' },
      { id: '4', name: 'Restaurant', apiEnum: 'RESTAURANT' },
      { id: '5', name: 'Retail Company', apiEnum: 'RETAIL_COMPANY' },
      { id: '6', name: 'Consulting Agency', apiEnum: 'CONSULTING_AGENCY' }
    ];

    let categories = fallbackCategories;
    if (q) {
      const search = q.toLowerCase();
      categories = categories.filter(cat => cat.name.toLowerCase().includes(search));
    }

    return res.status(200).json({
      success: true,
      categories
    });
  }
};

