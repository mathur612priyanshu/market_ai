const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Admin = require('../models/Admin');

const JWT_SECRET = process.env.JWT_SECRET || 'market_ai_jwt_secret_key';

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    // Find admin by email
    const admin = await Admin.findOne({ where: { email: email.toLowerCase() } });
    if (!admin) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    // Check account status
    if (admin.status === 'inactive') {
      return res.status(403).json({ success: false, message: 'This admin account has been deactivated' });
    }

    // Compare passwords
    const isMatch = await bcrypt.compare(password, admin.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: admin.id, email: admin.email, role: admin.role, isAdmin: true },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.status(200).json({
      success: true,
      token,
      admin: {
        id: admin.id,
        name: admin.name,
        email: admin.email,
        role: admin.role
      }
    });

  } catch (error) {
    console.error('Error in admin login controller:', error.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.me = async (req, res) => {
  try {
    const admin = await Admin.findByPk(req.user.id);
    if (!admin) {
      return res.status(404).json({ success: false, message: 'Admin not found' });
    }

    return res.status(200).json({
      success: true,
      admin: {
        id: admin.id,
        name: admin.name,
        email: admin.email,
        role: admin.role
      }
    });
  } catch (error) {
    console.error('Error in admin me controller:', error.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

const User = require('../models/User');
const SocialAccount = require('../models/SocialAccount');

exports.getUsers = async (req, res) => {
  try {
    const usersList = await User.findAll({
      include: [{
        model: SocialAccount,
        attributes: ['platform', 'accountName']
      }],
      order: [['createdAt', 'DESC']]
    });

    const formatted = usersList.map(user => {
      const platforms = user.SocialAccounts ? user.SocialAccounts.map(sa => sa.platform) : [];
      return {
        id: user.id,
        name: user.name || 'Anonymous User',
        email: user.email || 'N/A',
        phone: user.phone || 'N/A',
        plan: user.plan || 'Free',
        status: user.status || 'active',
        joined: user.createdAt ? user.createdAt.toISOString().split('T')[0] : 'N/A',
        platforms,
        usage: 0
      };
    });

    return res.status(200).json({ success: true, users: formatted });
  } catch (error) {
    console.error('Error fetching dynamic users:', error.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.updateUserPlan = async (req, res) => {
  try {
    const { id } = req.params;
    const { plan } = req.body;
    
    if (!plan) {
      return res.status(400).json({ success: false, message: 'Plan is required' });
    }

    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.plan = plan;
    await user.save();

    return res.status(200).json({ success: true, message: 'User plan updated successfully' });
  } catch (error) {
    console.error('Error updating user plan:', error.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

const ScheduledPost = require('../models/ScheduledPost');

exports.getPosts = async (req, res) => {
  try {
    const postsList = await ScheduledPost.findAll({
      include: [{
        model: User,
        attributes: ['name', 'email']
      }],
      order: [['createdAt', 'DESC']]
    });

    const formatted = postsList.map(post => ({
      id: post.id,
      userName: post.User ? post.User.name : 'Anonymous',
      userEmail: post.User ? post.User.email : 'N/A',
      platform: post.platform,
      caption: post.caption,
      hashtags: post.hashtags || '',
      mediaUrl: post.mediaUrl || '',
      scheduledTime: post.scheduledTime,
      status: post.status,
      errorMessage: post.errorMessage || '',
      prompt: post.prompt || 'N/A',
      tone: post.tone || 'N/A',
      type: post.type || 'N/A',
      createdAt: post.createdAt
    }));

    return res.status(200).json({ success: true, posts: formatted });
  } catch (error) {
    console.error('Error fetching admin posts list:', error.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

const CompetitorWatchlist = require('../models/CompetitorWatchlist');

const ApiUsage = require('../models/ApiUsage');

exports.getUsageStats = async (req, res) => {
  try {
    // Count exact logged executions of each service
    const geminiCalls = await ApiUsage.count({ where: { service: 'gemini' } });
    const apifyCrawls = await ApiUsage.count({ where: { service: 'apify' } });
    const metaCalls = await ApiUsage.count({ where: { service: 'meta' } });

    // Dynamic config checks
    const integrations = {
      gemini: {
        status: process.env.GEMINI_API_KEY ? 'active' : 'disabled',
        label: process.env.GEMINI_API_KEY ? 'Connected (Key configured)' : 'Missing API Key'
      },
      apify: {
        status: process.env.APIFY_TOKEN ? 'active' : 'disabled',
        label: process.env.APIFY_TOKEN ? 'Connected (Token configured)' : 'Missing Token'
      },
      meta: {
        status: ((process.env.FB_APP_ID || process.env.FACEBOOK_APP_ID) && (process.env.FB_APP_SECRET || process.env.FACEBOOK_APP_SECRET)) ? 'active' : 'disabled',
        label: ((process.env.FB_APP_ID || process.env.FACEBOOK_APP_ID) && (process.env.FB_APP_SECRET || process.env.FACEBOOK_APP_SECRET)) ? 'Connected (App Configured)' : 'Missing Credentials'
      }
    };

    return res.status(200).json({
      success: true,
      geminiCalls,
      apifyCrawls,
      metaCalls,
      integrations
    });
  } catch (error) {
    console.error('Error fetching admin usage stats:', error.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};
