const Lead = require('../models/Lead');
const ScheduledPost = require('../models/ScheduledPost');
const User = require('../models/User');
const SocialAccount = require('../models/SocialAccount');
const axios = require('axios');

const META_GRAPH_BASE_URL = `https://graph.facebook.com/${process.env.META_GRAPH_API_VERSION || 'v20.0'}`;
const VALID_TYPES = new Set(['competitor', 'ads', 'leads', 'roi', 'social']);
const TITLES = { competitor: 'Market Readiness Report', ads: 'Ad Performance Report', leads: 'Lead Generation Report', roi: 'ROI & Funnel Report', social: 'Social Media Operations Report' };
const number = value => Number(value || 0);
const percent = (value, total) => total ? Number((value / total * 100).toFixed(1)) : 0;
const metric = (label, value, detail, tone = 'neutral') => ({ label, value: String(value), detail, tone });
const today = () => new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
const socialPeriodDays = value => value === '7' ? 7 : 30;

function toCsvRow(values) {
  return values.map(value => {
    const text = String(value ?? '').replace(/"/g, '""');
    return /[,\n"]/.test(text) ? `"${text}"` : text;
  }).join(',') + '\r\n';
}

async function getMetaContext(userId, adAccountId) {
  if (!adAccountId || adAccountId === 'act_123456789') return { accountName: 'Demo Ad Account', unavailable: true };
  const account = await SocialAccount.findOne({ where: { userId, platform: 'facebook_user' } });
  if (!account) return { accountName: 'Connected ad account', unavailable: true };
  const id = adAccountId.startsWith('act_') ? adAccountId : `act_${adAccountId}`;
  try {
    const response = await axios.get(`${META_GRAPH_BASE_URL}/${id}`, { params: { fields: 'name,currency', access_token: account.accessToken }, timeout: 8000 });
    return { accountName: response.data.name || 'Connected ad account', currency: response.data.currency || 'USD', id, token: account.accessToken };
  } catch (error) { console.warn('Could not retrieve Meta account for report:', error.message); return { accountName: 'Connected ad account', unavailable: true }; }
}

async function getAdMetrics(context) {
  if (context.unavailable) return { available: false };
  try {
    const response = await axios.get(`${META_GRAPH_BASE_URL}/${context.id}/insights`, { params: { date_preset: 'last_30d', fields: 'spend,impressions,reach,clicks,ctr,cpc,actions,action_values', access_token: context.token }, timeout: 10000 });
    const raw = response.data.data?.[0];
    if (!raw) return { available: false };
    const action = (type, values = raw.actions) => number(values?.find(item => item.action_type === type)?.value);
    return { available: true, spend: number(raw.spend), impressions: number(raw.impressions), reach: number(raw.reach), clicks: number(raw.clicks), ctr: number(raw.ctr), cpc: number(raw.cpc), leads: action('lead') + action('onsite_conversion.lead_grouped'), purchaseValue: action('purchase', raw.action_values), currency: context.currency || 'USD' };
  } catch (error) { console.warn('Could not retrieve Meta insights for report:', error.message); return { available: false }; }
}

async function getLocalMetrics(userId) {
  const since = new Date(); since.setDate(since.getDate() - 30);
  const [leads, posts] = await Promise.all([Lead.findAll({ where: { userId }, order: [['submittedAt', 'DESC']] }), ScheduledPost.findAll({ where: { userId }, order: [['scheduledTime', 'DESC']] })]);
  const leadMetrics = { total: leads.length, new: 0, contacted: 0, converted: 0, last30: 0, missingContact: 0 };
  leads.forEach(lead => { const status = String(lead.status || '').toLowerCase(); if (status === 'new') leadMetrics.new++; if (status === 'contacted') leadMetrics.contacted++; if (status === 'converted') leadMetrics.converted++; if (lead.submittedAt && new Date(lead.submittedAt) >= since) leadMetrics.last30++; if (!lead.email && !lead.phone) leadMetrics.missingContact++; });
  const postMetrics = { total: posts.length, pending: 0, published: 0, failed: 0, upcoming: 0 };
  posts.forEach(post => { const status = String(post.status || '').toLowerCase(); if (Object.hasOwn(postMetrics, status)) postMetrics[status]++; if (status === 'pending' && new Date(post.scheduledTime) >= new Date()) postMetrics.upcoming++; });
  return { leads, posts, leadMetrics, postMetrics };
}

async function getSocialAccounts(userId) {
  const accounts = await SocialAccount.findAll({
    where: { userId, platform: ['facebook', 'instagram'] },
    attributes: ['accountId', 'accountName', 'platform', 'profilePicture'],
    order: [['platform', 'ASC'], ['accountName', 'ASC']]
  });
  return accounts.map(account => ({
    id: account.accountId,
    name: account.accountName,
    platform: account.platform,
    profilePicture: account.profilePicture
  }));
}

function totalMetric(payload, metricName) {
  const item = payload.data?.find(value => value.name === metricName);
  if (!item) return 0;
  return (item.values || []).reduce((total, value) => total + number(value.value), 0);
}

function metaError(result) {
  if (result.status !== 'rejected') return null;
  return result.reason?.response?.data?.error?.message || result.reason?.message || 'Unknown Meta API error';
}

async function getSocialPerformance(userId, socialAccountId, requestedPeriod) {
  const accounts = await getSocialAccounts(userId);
  const selected = accounts.find(account => account.id === socialAccountId) || accounts[0];
  if (!selected) return { available: false, accounts, reason: 'Connect a Facebook Page or Instagram professional account to view live social insights.' };
  const account = await SocialAccount.findOne({ where: { userId, accountId: selected.id, platform: selected.platform } });
  const days = socialPeriodDays(requestedPeriod);
  const until = new Date(); const since = new Date(until); since.setDate(since.getDate() - days);
  const baseParams = { access_token: account.accessToken, since: Math.floor(since.getTime() / 1000), until: Math.floor(until.getTime() / 1000) };
  const isFacebook = selected.platform === 'facebook';
  const [profileResult, contentResult, insightResult] = await Promise.allSettled([
    axios.get(`${META_GRAPH_BASE_URL}/${selected.id}`, { params: { access_token: account.accessToken, fields: isFacebook ? 'id,name,followers_count' : 'id,username,followers_count,media_count' }, timeout: 10000 }),
    axios.get(`${META_GRAPH_BASE_URL}/${selected.id}/${isFacebook ? 'posts' : 'media'}`, { params: { ...baseParams, limit: 100, fields: isFacebook ? 'id,message,created_time,permalink_url' : 'id,caption,media_type,permalink,timestamp,like_count,comments_count' }, timeout: 10000 }),
    axios.get(`${META_GRAPH_BASE_URL}/${selected.id}/insights`, { params: { ...baseParams, period: 'day', metric: isFacebook ? 'page_impressions_unique,page_post_engagements' : 'reach,accounts_engaged,total_interactions,profile_views' }, timeout: 10000 })
  ]);
  const errors = [metaError(profileResult), metaError(contentResult), metaError(insightResult)].filter(Boolean);
  const profile = profileResult.status === 'fulfilled' ? profileResult.value.data : {};
  const content = contentResult.status === 'fulfilled' ? (contentResult.value.data.data || []) : [];
  const topPosts = content.map(post => {
    const reactions = number(isFacebook ? 0 : post.like_count);
    const comments = number(isFacebook ? 0 : post.comments_count);
    const shares = 0;
    return { id: post.id, text: post.message || post.caption || `${isFacebook ? 'Facebook' : 'Instagram'} post`, permalink: post.permalink_url || post.permalink, createdAt: post.created_time || post.timestamp, reactions, comments, shares, engagement: reactions + comments + shares };
  }).sort((a, b) => b.engagement - a.engagement).slice(0, 5);
  const insights = insightResult.status === 'fulfilled' ? insightResult.value.data : { data: [] };
  const hasInsights = insightResult.status === 'fulfilled';
  const hasContent = contentResult.status === 'fulfilled';
  return {
    available: hasInsights || hasContent,
    hasInsights,
    hasContent,
    accounts,
    selected,
    days,
    topPosts,
    reach: totalMetric(insights, isFacebook ? 'page_impressions_unique' : 'reach'),
    engagement: totalMetric(insights, isFacebook ? 'page_post_engagements' : 'total_interactions'),
    engagedAccounts: totalMetric(insights, 'accounts_engaged'),
    profileViews: totalMetric(insights, 'profile_views'),
    followers: number(profile.followers_count),
    source: isFacebook ? 'Facebook Page Insights' : 'Instagram Insights',
    fetchedAt: new Date().toISOString(),
    reason: errors.length ? `Meta response: ${errors[0]}` : null
  };
}

async function buildReport(type, userId, adAccountId, socialAccountId, requestedPeriod) {
  const [user, local, context] = await Promise.all([User.findByPk(userId), getLocalMetrics(userId), getMetaContext(userId, adAccountId)]);
  const business = user?.businessName || 'Your business'; const industry = user?.industry || 'your market';
  const leads = local.leadMetrics; const posts = local.postMetrics;
  let summary = ''; let metrics = []; let insights = []; let actions = []; let dataStatus = 'Based on your connected app data.'; let period = 'Current account snapshot';
  if (type === 'leads') {
    const rate = percent(leads.converted, leads.total);
    summary = leads.total ? `${business} has ${leads.total} captured leads, with ${leads.converted} converted (${rate}%).` : `No leads have been synced for ${business} yet.`;
    metrics = [metric('Total leads', leads.total, `${leads.last30} received in the last 30 days`), metric('Conversion rate', `${rate}%`, `${leads.converted} converted`, rate >= 10 ? 'positive' : 'neutral'), metric('Needs follow-up', leads.new, 'Leads still marked New', leads.new ? 'attention' : 'positive')];
    insights = [`${leads.contacted} leads are in the contacted stage.`, leads.total ? `${percent(leads.new, leads.total)}% of the pipeline is awaiting first contact.` : 'Connect a Facebook Lead Form to begin measuring lead quality.'];
    actions = [leads.new ? `Contact the ${leads.new} new lead${leads.new === 1 ? '' : 's'} first and record the outcome.` : 'Keep lead statuses current to maintain a reliable conversion rate.', ...(leads.missingContact ? [`Review ${leads.missingContact} lead${leads.missingContact === 1 ? '' : 's'} without an email or phone number.`] : [])];
  } else if (type === 'social') {
    const performance = await getSocialPerformance(userId, socialAccountId, requestedPeriod);
    period = `Last ${performance.days || socialPeriodDays(requestedPeriod)} days • ${performance.source || 'Social activity'}`;
    if (!performance.available) {
      dataStatus = performance.reason || 'Live social insights are unavailable.';
      summary = posts.total ? `${posts.total} posts are in your publishing workflow, but live social metrics could not be retrieved.` : 'No live social insights are available yet.';
      metrics = [metric('Posts in workflow', posts.total, `${posts.published} published`), metric('Upcoming posts', posts.upcoming, 'Pending posts scheduled in the future', posts.upcoming ? 'positive' : 'attention'), metric('Failed posts', posts.failed, 'Require review or rescheduling', posts.failed ? 'attention' : 'positive')];
      insights = ['No estimated Facebook or Instagram performance has been used in this report.'];
      actions = ['Reconnect the selected account after granting the insights permissions, then refresh this report.'];
    } else {
      const top = performance.topPosts[0];
      dataStatus = performance.hasInsights
        ? `Live ${performance.source} data fetched from Meta at ${new Date(performance.fetchedAt).toLocaleTimeString()}.`
        : `Live posts were fetched from Meta, but account-level insights were not returned. ${performance.reason || 'Reconnect after granting insights access.'}`;
      summary = performance.hasInsights
        ? `${performance.selected.name} generated ${performance.reach.toLocaleString()} Meta-reported reach and ${performance.engagement.toLocaleString()} interactions in the last ${performance.days} days.`
        : `${performance.selected.name} has ${performance.topPosts.length} live post${performance.topPosts.length === 1 ? '' : 's'} returned by Meta for the selected period. Account-level insights are unavailable.`;
      metrics = performance.hasInsights
        ? [metric('Reach', performance.reach.toLocaleString(), `Meta-reported daily total • ${performance.days} days`), metric('Interactions', performance.engagement.toLocaleString(), performance.selected.platform === 'instagram' ? `${performance.engagedAccounts.toLocaleString()} engaged accounts` : 'Page post engagement'), metric('Followers', performance.followers.toLocaleString(), performance.selected.platform === 'instagram' ? 'Instagram professional account' : 'Facebook Page'), metric('Top posts', performance.topPosts.length, 'Ranked by visible engagement')]
        : [metric('Live posts', performance.topPosts.length, `Fetched from ${performance.selected.name}`), metric('Followers', performance.followers.toLocaleString(), 'Live account profile data'), metric('Account insights', 'Unavailable', 'Meta did not authorize this request', 'attention')];
      insights = [top ? `Top content: “${top.text.slice(0, 80)}${top.text.length > 80 ? '…' : ''}” with ${top.engagement} visible interactions.` : 'No posts were returned by Meta for the selected period.', posts.upcoming ? `${posts.upcoming} post${posts.upcoming === 1 ? ' is' : 's are'} still queued in your app.` : 'There are no upcoming posts in the app queue.'];
      actions = [top ? 'Reuse the topic, creative format, or call-to-action from the top post in a new variation.' : 'Publish consistently during the next reporting period to establish a performance baseline.', posts.failed ? `Resolve ${posts.failed} failed scheduled post${posts.failed === 1 ? '' : 's'}.` : 'Use the 7-day view to evaluate recent experiments before making content changes.'];
      return { context, local, report: { title: TITLES[type], date: today(), period, generatedAt: new Date().toISOString(), summary, metrics, insights, actions, dataStatus, socialAccounts: performance.accounts, selectedSocialAccountId: performance.selected.id, selectedSocialAccountName: performance.selected.name, selectedSocialAccountPlatform: performance.selected.platform, topPosts: performance.topPosts } };
    }
  } else if (type === 'competitor') {
    summary = `Market readiness overview for ${business} in ${industry}. This report uses your first-party funnel and publishing activity; competitor intelligence is not fabricated when no competitor source is connected.`;
    metrics = [metric('Leads captured', leads.total, `${leads.last30} in the last 30 days`), metric('Lead conversion', `${percent(leads.converted, leads.total)}%`, `${leads.converted} converted`), metric('Content queue', posts.upcoming, 'Posts scheduled ahead')];
    insights = [leads.total ? 'Your lead pipeline provides a baseline for measuring market response.' : 'Capture first-party leads before drawing conclusions about demand.', posts.upcoming ? 'A forward content queue supports consistent market visibility.' : 'No upcoming content is scheduled, limiting organic visibility.'];
    actions = ['Add verified competitors to the watchlist to unlock evidence-based competitor comparisons.', leads.new ? `Follow up with ${leads.new} new leads to understand the objections and messages shaping demand.` : 'Tag incoming leads by source and offer to identify winning messages.'];
  } else {
    const ads = await getAdMetrics(context); period = ads.available ? 'Last 30 days • Meta delivery data' : period;
    if (!ads.available) {
      dataStatus = 'Meta delivery data is unavailable. Connect a live Meta ad account to populate spend and delivery metrics.';
      summary = type === 'ads' ? 'No live Meta delivery data is available for this account.' : `Funnel status for ${business} is based on synced leads because campaign spend is unavailable.`;
      metrics = [metric('Synced leads', leads.total, `${leads.converted} converted`), metric('Lead conversion', `${percent(leads.converted, leads.total)}%`, 'Based on lead status'), metric('Ad spend', '—', 'Connect Meta to measure spend', 'attention')];
      insights = ['No sample ad performance has been inserted into this report.', leads.total ? 'Lead status data is available and can be used to improve follow-up.' : 'Sync leads and Meta insights to establish a baseline.'];
      actions = ['Reconnect the Facebook profile that has access to this ad account.', 'Check that the selected ad account has delivered ads in the reporting period.'];
    } else if (type === 'ads') {
      summary = `${business} spent ${ads.currency} ${ads.spend.toFixed(2)} to reach ${ads.reach.toLocaleString()} people and generate ${ads.clicks.toLocaleString()} clicks in the last 30 days.`;
      metrics = [metric('Spend', `${ads.currency} ${ads.spend.toFixed(2)}`, 'Last 30 days'), metric('CTR', `${ads.ctr.toFixed(2)}%`, `${ads.clicks.toLocaleString()} link clicks`, ads.ctr >= 1 ? 'positive' : 'attention'), metric('Cost per click', `${ads.currency} ${ads.cpc.toFixed(2)}`, `${ads.impressions.toLocaleString()} impressions`), metric('Meta leads', ads.leads, 'Reported by Meta')];
      insights = [`Average frequency is ${ads.reach ? (ads.impressions / ads.reach).toFixed(2) : '0.00'} impressions per reached person.`, ads.leads ? `Cost per Meta lead is ${ads.currency} ${(ads.spend / ads.leads).toFixed(2)}.` : 'Meta has not reported lead actions for this period.'];
      actions = [ads.ctr < 1 ? 'Test a stronger creative hook and call-to-action to improve click-through rate.' : 'Preserve the current creative direction and test one focused variation.', ads.leads ? 'Compare Meta lead actions with synced leads to identify tracking gaps.' : 'Verify Lead Form or Pixel conversion events are configured correctly.'];
    } else {
      const roas = ads.spend > 0 && ads.purchaseValue ? ads.purchaseValue / ads.spend : null;
      summary = `ROI overview for ${business}: ${ads.currency} ${ads.spend.toFixed(2)} in tracked ad spend and ${leads.converted} locally converted leads in the current pipeline.`;
      metrics = [metric('Ad spend', `${ads.currency} ${ads.spend.toFixed(2)}`, 'Last 30 days'), metric('Cost / Meta lead', ads.leads ? `${ads.currency} ${(ads.spend / ads.leads).toFixed(2)}` : '—', `${ads.leads} Meta lead actions`), metric('Pipeline conversion', `${percent(leads.converted, leads.total)}%`, `${leads.converted} converted leads`), metric('ROAS', roas ? `${roas.toFixed(2)}x` : '—', roas ? 'Based on tracked purchase value' : 'Purchase value is not tracked')];
      insights = [ads.leads ? `${ads.leads} lead actions were reported by Meta.` : 'No Meta lead actions were reported.', roas ? 'ROAS is calculated from Meta-attributed purchase value and ad spend.' : 'Revenue is not inferred from lead conversions; connect purchase-value tracking for true ROAS.'];
      actions = [roas ? 'Review campaigns with low contribution to tracked purchase value.' : 'Send purchase values with your Pixel or Conversions API to calculate ROAS.', leads.new ? `Prioritize ${leads.new} new leads; faster follow-up protects paid-media ROI.` : 'Continue maintaining lead-stage data for reliable funnel reporting.'];
    }
  }
  return { context, local, report: { title: TITLES[type], date: today(), period, generatedAt: new Date().toISOString(), summary, metrics, insights, actions, dataStatus } };
}

exports.listReports = async (req, res) => {
  try {
    let adAccountId = req.query.adAccountId;
    if (!adAccountId || adAccountId === 'act_123456789' || adAccountId === 'null' || adAccountId === 'undefined' || adAccountId === '') {
      const defaultAccount = await SocialAccount.findOne({ where: { userId: req.user.id, platform: 'facebook_user' } });
      if (defaultAccount) adAccountId = defaultAccount.accountId;
    }
    const [context, leads, posts] = await Promise.all([
      getMetaContext(req.user.id, adAccountId),
      Lead.count({ where: { userId: req.user.id } }),
      ScheduledPost.count({ where: { userId: req.user.id } })
    ]);
    const items = [['competitor', 'Competitor', 'analytics_outlined', 'A first-party market-readiness baseline with clear data limitations.'], ['ads', 'Ads', 'campaign_outlined', 'Live Meta spend, delivery and click metrics for the last 30 days.'], ['leads', 'Leads', 'people_outline_rounded', `${leads} synced leads with funnel-stage and follow-up metrics.`], ['roi', 'ROI', 'show_chart_rounded', 'Paid media, lead pipeline and revenue-tracking readiness.'], ['social', 'Social', 'post_add_outlined', 'Live Facebook or Instagram insights with top-performing content.']];
    res.json({ success: true, accountName: context.accountName, reports: items.map(([id, category, iconName, description]) => ({ id, title: TITLES[id], category, iconName, description, date: today() })) });
  } catch (error) { console.error('Error listing reports:', error.message); res.status(500).json({ success: false, error: 'Internal Server Error' }); }
};

exports.listSocialAccounts = async (req, res) => {
  try {
    const accounts = await getSocialAccounts(req.user.id);
    return res.json({ success: true, accounts });
  } catch (error) {
    console.error('Error listing social accounts:', error.message);
    return res.status(500).json({ success: false, error: 'Internal Server Error' });
  }
};

exports.getReportDetails = async (req, res) => {
  if (!VALID_TYPES.has(req.params.type)) return res.status(400).json({ success: false, error: 'Unknown report type.' });
  try {
    let adAccountId = req.query.adAccountId;
    if (!adAccountId || adAccountId === 'act_123456789' || adAccountId === 'null' || adAccountId === 'undefined' || adAccountId === '') {
      const defaultAccount = await SocialAccount.findOne({ where: { userId: req.user.id, platform: 'facebook_user' } });
      if (defaultAccount) adAccountId = defaultAccount.accountId;
    }
    const output = await buildReport(req.params.type, req.user.id, adAccountId, req.query.socialAccountId, req.query.period);
    res.json({ success: true, accountName: output.context.accountName, report: output.report });
  }
  catch (error) { console.error('Error fetching report details:', error.message); res.status(500).json({ success: false, error: 'Internal Server Error' }); }
};

exports.downloadReport = async (req, res) => {
  if (!VALID_TYPES.has(req.params.type)) return res.status(400).json({ success: false, error: 'Unknown report type.' });
  try {
    let adAccountId = req.query.adAccountId;
    if (!adAccountId || adAccountId === 'act_123456789' || adAccountId === 'null' || adAccountId === 'undefined' || adAccountId === '') {
      const defaultAccount = await SocialAccount.findOne({ where: { userId: req.user.id, platform: 'facebook_user' } });
      if (defaultAccount) adAccountId = defaultAccount.accountId;
    }
    const { report, context, local } = await buildReport(req.params.type, req.user.id, adAccountId, req.query.socialAccountId, req.query.period);
    
    let csv = '\ufeff'; 
    csv += toCsvRow(['==================================================']);
    csv += toCsvRow(['            MARKET AI PERFORMANCE REPORT          ']);
    csv += toCsvRow(['==================================================']);
    csv += toCsvRow(['Report Title', report.title]);
    csv += toCsvRow(['Meta Ad Account', context.accountName]);
    if (report.selectedSocialAccountName) {
      const platformLabel = report.selectedSocialAccountPlatform === 'instagram' ? 'Instagram' : 'Facebook';
      csv += toCsvRow(['Social Account', `${platformLabel} • ${report.selectedSocialAccountName}`]);
    }
    csv += toCsvRow(['Reporting Period', report.period]);
    csv += toCsvRow(['Generated On', new Date(report.generatedAt).toLocaleString()]);
    csv += toCsvRow(['Data Status', report.dataStatus]);
    csv += toCsvRow(['==================================================']);
    csv += toCsvRow([]);

    csv += toCsvRow(['1. SUMMARY OVERVIEW']);
    csv += toCsvRow(['--------------------------------------------------']);
    csv += toCsvRow([report.summary]);
    csv += toCsvRow([]);

    csv += toCsvRow(['2. KEY PERFORMANCE METRICS']);
    csv += toCsvRow(['--------------------------------------------------']);
    csv += toCsvRow(['Metric', 'Value', 'Context']);
    report.metrics.forEach(item => { 
      csv += toCsvRow([item.label, item.value, item.detail]); 
    });
    csv += toCsvRow([]);

    csv += toCsvRow(['3. STRATEGIC INSIGHTS']);
    csv += toCsvRow(['--------------------------------------------------']);
    report.insights.forEach((item, index) => { 
      csv += toCsvRow([`Insight #${index + 1}`, item]); 
    });
    csv += toCsvRow([]);

    csv += toCsvRow(['4. RECOMMENDED NEXT STEPS']);
    csv += toCsvRow(['--------------------------------------------------']);
    report.actions.forEach((item, index) => { 
      csv += toCsvRow([`Action #${index + 1}`, item]); 
    });
    csv += toCsvRow([]);

    if (req.params.type === 'leads' && Array.isArray(local.leads)) { 
      csv += toCsvRow(['5. LEAD DETAIL PIPELINE']);
      csv += toCsvRow(['--------------------------------------------------']);
      csv += toCsvRow(['Lead ID', 'Name', 'Email', 'Phone', 'Status', 'Submitted at']); 
      local.leads.forEach(lead => { 
        csv += toCsvRow([
          lead.id, 
          lead.name || 'N/A', 
          lead.email || 'N/A', 
          lead.phone || 'N/A', 
          lead.status || 'New', 
          lead.submittedAt ? new Date(lead.submittedAt).toLocaleString() : 'N/A'
        ]); 
      }); 
      csv += toCsvRow([]);
    }

    if (req.params.type === 'social') { 
      if (Array.isArray(local.posts) && local.posts.length > 0) {
        csv += toCsvRow(['5. SOCIAL PUBLISHING WORKFLOW']);
        csv += toCsvRow(['--------------------------------------------------']);
        csv += toCsvRow(['Post ID', 'Platform', 'Scheduled Time', 'Status', 'Caption']); 
        local.posts.forEach(post => { 
          csv += toCsvRow([
            post.id, 
            post.platform, 
            post.scheduledTime ? new Date(post.scheduledTime).toLocaleString() : 'N/A', 
            post.status, 
            post.caption || ''
          ]); 
        }); 
        csv += toCsvRow([]);
      }

      if (Array.isArray(report.topPosts) && report.topPosts.length > 0) { 
        csv += toCsvRow(['6. TOP PERFORMING META POSTS']);
        csv += toCsvRow(['--------------------------------------------------']);
        csv += toCsvRow(['Post Caption', 'Published Date', 'Likes & Reactions', 'Comments', 'Shares', 'Total Engagement', 'Post URL']); 
        report.topPosts.forEach(post => { 
          csv += toCsvRow([
            post.text, 
            post.createdAt ? new Date(post.createdAt).toLocaleString() : 'N/A', 
            post.reactions, 
            post.comments, 
            post.shares, 
            post.engagement, 
            post.permalink || 'N/A'
          ]); 
        }); 
        csv += toCsvRow([]);
      }
    }

    const stamp = new Date().toISOString().slice(0, 10); 
    res.setHeader('Content-Type', 'text/csv; charset=utf-8'); 
    res.setHeader('Content-Disposition', `attachment; filename="${req.params.type}_report_${stamp}.csv"`); 
    res.send(csv);
  } catch (error) { 
    console.error('Error downloading report:', error.message); 
    res.status(500).json({ success: false, error: 'Internal Server Error' }); 
  }
};
