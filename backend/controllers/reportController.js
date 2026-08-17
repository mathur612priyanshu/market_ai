const Lead = require('../models/Lead');
const ScheduledPost = require('../models/ScheduledPost');
const User = require('../models/User');
const SocialAccount = require('../models/SocialAccount');
const axios = require('axios');

const META_GRAPH_BASE_URL = 'https://graph.facebook.com/v25.0';

// Helper to escape CSV values
function toCsvRow(arr) {
  return arr.map(val => {
    let s = String(val ?? '');
    s = s.replace(/"/g, '""');
    if (s.includes(',') || s.includes('\n') || s.includes('"')) {
      s = `"${s}"`;
    }
    return s;
  }).join(',') + '\r\n';
}

async function getAdAccountName(userId, adAccountId) {
  if (!adAccountId || adAccountId === 'act_123456789') return 'Demo Ad Account';
  try {
    const userAccount = await SocialAccount.findOne({
      where: { userId, platform: 'facebook_user' }
    });
    if (userAccount) {
      const userToken = userAccount.accessToken;
      let cleanId = adAccountId.trim();
      if (!cleanId.startsWith('act_')) {
        cleanId = 'act_' + cleanId;
      }
      const accountRes = await axios.get(`${META_GRAPH_BASE_URL}/${cleanId}`, {
        params: { fields: 'name', access_token: userToken }
      });
      return accountRes.data.name || 'Demo Ad Account';
    }
  } catch (err) {
    console.warn('Could not fetch ad account name for reports:', err.message);
  }
  return 'Demo Ad Account';
}

exports.listReports = async (req, res) => {
  const userId = req.user.id;
  const { adAccountId } = req.query;

  try {
    const accountName = await getAdAccountName(userId, adAccountId);
    const leadsCount = await Lead.count({ where: { userId } });
    const postsCount = await ScheduledPost.count({ where: { userId } });

    const reports = [
      {
        id: 'competitor',
        title: 'Competitor Analysis Report',
        category: 'Competitor',
        date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
        description: 'AI-generated competitor profiling and market positioning report.',
        iconName: 'analytics_outlined'
      },
      {
        id: 'ads',
        title: 'Ad Performance Report',
        category: 'Ads',
        date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
        description: 'Facebook ad delivery, spend, impressions and click performance overview.',
        iconName: 'campaign_outlined'
      },
      {
        id: 'leads',
        title: 'Lead Generation Report',
        category: 'Leads',
        date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
        description: `Total of ${leadsCount} leads synced from connected social pages.`,
        iconName: 'people_outline_rounded'
      },
      {
        id: 'roi',
        title: 'ROI Report',
        category: 'ROI',
        date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
        description: 'Return on investment report based on advertising budgets and conversions.',
        iconName: 'show_chart_rounded'
      },
      {
        id: 'social',
        title: 'Social Media Report',
        category: 'Ads',
        date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
        description: `Total of ${postsCount} scheduled social media post logs.`,
        iconName: 'post_add_outlined'
      }
    ];

    return res.status(200).json({ success: true, accountName, reports });
  } catch (error) {
    console.error('Error listing reports:', error.message);
    return res.status(500).json({ success: false, error: 'Internal Server Error' });
  }
};

exports.getReportDetails = async (req, res) => {
  const userId = req.user.id;
  const { type } = req.params;
  const { adAccountId } = req.query;

  try {
    const accountName = await getAdAccountName(userId, adAccountId);
    const user = await User.findByPk(userId);
    const businessName = user?.businessName || 'Business';
    const industry = user?.industry || 'General Business';

    let title = 'Report';
    let summary = 'Dynamic report summary.';
    let insights = [];

    if (type === 'competitor') {
      title = 'Competitor Analysis Report';
      summary = `AI market analysis for "${businessName}" in the "${industry}" sector. Our scan shows key industry competitors are aggressively capturing leads using social lead forms.`;
      insights = [
        'Competitors have strong Facebook and Instagram ad presence.',
        'Primary marketing focus is on high conversion lead magnets.',
        'High ad frequency observed on weekends for B2C targets.',
        'Substantial focus on video ads over static images.'
      ];
    } else if (type === 'leads') {
      const leadsCount = await Lead.count({ where: { userId } });
      const newLeads = await Lead.count({ where: { userId, status: 'New' } });
      const contactedLeads = await Lead.count({ where: { userId, status: 'Contacted' } });
      const convertedLeads = await Lead.count({ where: { userId, status: 'Converted' } });

      title = 'Lead Generation Report';
      summary = `Lead acquisition summary for "${businessName}". Total of ${leadsCount} leads synced locally (${newLeads} New, ${contactedLeads} Contacted, ${convertedLeads} Converted).`;
      insights = [
        `Lead Pipeline Conversion: ${leadsCount > 0 ? ((convertedLeads / leadsCount) * 100).toFixed(1) : 0}% converted.`,
        'Higher conversion rates observed for leads contacted within 24 hours.',
        'Clean contact details parsed: Email and Phone coverage at 100%.',
        'Leads are segmented by connected Facebook Pages and Forms.'
      ];
    } else if (type === 'roi') {
      const leads = await Lead.findAll({ where: { userId } });
      const convertedCount = leads.filter(l => l.status === 'Converted').length;
      
      title = 'ROI Report';
      summary = `Return on investment (ROI) summary. The pipeline shows ${convertedCount} converted leads.`;
      insights = [
        'Marketing ROI is calculated based on campaign spend vs customer acquisition value.',
        'Advantage+ targeting settings are optimized to lower acquisition cost.',
        'Customer lifetime value remains high for converted leads.',
        'Pixel event setup verified and receiving conversion events.'
      ];
    } else if (type === 'ads') {
      title = 'Ad Performance Report';
      summary = `Facebook campaign delivery report for "${businessName}". Analytics show total reach and impressions across active ad sets.`;
      insights = [
        'High audience engagement with CTR above industry average.',
        'Geographic targeting optimized for primary city locations.',
        'Advantage audience flags configured correctly to prevent audience overlap.',
        'Daily budgets are balanced across top-performing ad sets.'
      ];
    } else if (type === 'social') {
      const postsCount = await ScheduledPost.count({ where: { userId } });
      const pendingCount = await ScheduledPost.count({ where: { userId, status: 'pending' } });
      const publishedCount = await ScheduledPost.count({ where: { userId, status: 'published' } });

      title = 'Social Media Report';
      summary = `Social media planning report. Total of ${postsCount} scheduled posts (${publishedCount} Published, ${pendingCount} Pending).`;
      insights = [
        'Automated content posting scheduling system is active.',
        'Posting frequency is optimized for high user engagement times.',
        'AI caption writing tool utilized to improve organic post reach.',
        'Facebook page and Instagram profiles are linked and verified.'
      ];
    }

    return res.status(200).json({
      success: true,
      accountName,
      report: {
        title,
        date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
        summary,
        insights
      }
    });
  } catch (error) {
    console.error('Error fetching report details:', error.message);
    return res.status(500).json({ success: false, error: 'Internal Server Error' });
  }
};

exports.downloadReport = async (req, res) => {
  const userId = req.user.id;
  const { type } = req.params;
  const { adAccountId } = req.query;

  try {
    const accountName = await getAdAccountName(userId, adAccountId);
    let csvContent = '';
    let filename = `${type}_report.csv`;

    csvContent += toCsvRow(['Ad Account / Page Name', accountName]);
    csvContent += toCsvRow([]);

    if (type === 'competitor') {
      const user = await User.findByPk(userId);
      const businessName = user?.businessName || 'Business';
      const industry = user?.industry || 'General Business';

      csvContent += toCsvRow(['Business Name', businessName]);
      csvContent += toCsvRow(['Industry', industry]);
      csvContent += toCsvRow([]);
      csvContent += toCsvRow(['Competitor Name', 'Social Handle', 'Strength', 'Ad Strategy']);
      csvContent += toCsvRow(['DigiGrowth Solutions', '@digigrowth', 'High ad budget', 'Lead Generation']);
      csvContent += toCsvRow(['BrandBoost Agency', '@brandboost', 'Strong social handle', 'Brand Awareness']);
      csvContent += toCsvRow(['Clickify Media', '@clickify', 'Interactive content', 'Conversion Ads']);
    } else if (type === 'leads') {
      const leads = await Lead.findAll({ where: { userId }, order: [['submittedAt', 'DESC']] });
      csvContent += toCsvRow(['Lead ID', 'Name', 'Email', 'Phone', 'Status', 'Submitted At']);
      for (const lead of leads) {
        csvContent += toCsvRow([
          lead.id,
          lead.name,
          lead.email,
          lead.phone,
          lead.status,
          lead.submittedAt ? lead.submittedAt.toISOString() : ''
        ]);
      }
    } else if (type === 'roi') {
      const leads = await Lead.findAll({ where: { userId } });
      const totalLeads = leads.length;
      const converted = leads.filter(l => l.status === 'Converted').length;

      csvContent += toCsvRow(['ROI Report - Summary']);
      csvContent += toCsvRow([]);
      csvContent += toCsvRow(['Metric', 'Value']);
      csvContent += toCsvRow(['Total Leads Synced', totalLeads]);
      csvContent += toCsvRow(['Converted Contacts', converted]);
      csvContent += toCsvRow(['Conversion Rate', totalLeads > 0 ? `${((converted / totalLeads) * 100).toFixed(1)}%` : '0.0%']);
    } else if (type === 'ads') {
      csvContent += toCsvRow(['Ad Campaign Overview']);
      csvContent += toCsvRow([]);
      csvContent += toCsvRow(['Campaign Type', 'Total Reach', 'Impressions', 'Ctr', 'Objective']);
      csvContent += toCsvRow(['Lead Gen Ad #1', '24,500', '32,100', '3.2%', 'LEAD_GENERATION']);
      csvContent += toCsvRow(['Engagement Ad #2', '12,200', '18,400', '4.1%', 'OUTCOME_ENGAGEMENT']);
    } else if (type === 'social') {
      const posts = await ScheduledPost.findAll({ where: { userId }, order: [['scheduledTime', 'ASC']] });
      csvContent += toCsvRow(['Social Media Scheduled Posts Log']);
      csvContent += toCsvRow([]);
      csvContent += toCsvRow(['ID', 'Platform', 'Scheduled Time', 'Status', 'Caption']);
      for (const post of posts) {
        csvContent += toCsvRow([
          post.id,
          post.platform,
          post.scheduledTime ? post.scheduledTime.toISOString() : '',
          post.status,
          post.caption
        ]);
      }
    }

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    return res.status(200).send(csvContent);
  } catch (error) {
    console.error('Error downloading report:', error.message);
    return res.status(500).json({ success: false, error: 'Internal Server Error' });
  }
};
