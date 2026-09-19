const Lead = require('../models/Lead');
const ScheduledPost = require('../models/ScheduledPost');
const User = require('../models/User');
const SocialAccount = require('../models/SocialAccount');
const axios = require('axios');

const META_GRAPH_BASE_URL = `https://graph.facebook.com/${process.env.META_GRAPH_API_VERSION || 'v20.0'}`;
const VALID_TYPES = new Set(['ads', 'leads', 'roi', 'social']);
const TITLES = {
  ads: 'Ad Performance Report',
  leads: 'Lead Generation Report',
  roi: 'ROI & Funnel Report',
  social: 'Social Media Operations Report'
};

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

async function getFacebookPages(userId) {
  const accounts = await SocialAccount.findAll({
    where: { userId, platform: 'facebook' },
    attributes: ['accountId', 'accountName', 'platform', 'profilePicture', 'accessToken'],
    order: [['accountName', 'ASC']]
  });
  return accounts.map(account => ({
    id: account.accountId,
    name: account.accountName,
    platform: account.platform,
    profilePicture: account.profilePicture
  }));
}

async function getMetaContext(userId, adAccountId) {
  if (!adAccountId || adAccountId === 'act_123456789' || adAccountId === 'null' || adAccountId === 'undefined') {
    // Pick first available ad account for this user
    const userAcc = await SocialAccount.findOne({ where: { userId, platform: 'facebook_user' } });
    if (userAcc) {
      try {
        const res = await axios.get(`${META_GRAPH_BASE_URL}/me/adaccounts`, {
          params: { fields: 'id,name,currency', access_token: userAcc.accessToken },
          timeout: 6000
        });
        const first = res.data?.data?.[0];
        if (first) {
          return { accountName: first.name, currency: first.currency || 'INR', id: first.id, token: userAcc.accessToken };
        }
      } catch (_) {}
    }
    return { accountName: 'Demo Ad Account', unavailable: true };
  }

  const account = await SocialAccount.findOne({ where: { userId, platform: 'facebook_user' } });
  if (!account) return { accountName: 'Connected ad account', unavailable: true };
  const id = adAccountId.startsWith('act_') ? adAccountId : `act_${adAccountId}`;
  try {
    const response = await axios.get(`${META_GRAPH_BASE_URL}/${id}`, { params: { fields: 'name,currency', access_token: account.accessToken }, timeout: 8000 });
    return { accountName: response.data.name || 'Connected ad account', currency: response.data.currency || 'INR', id, token: account.accessToken };
  } catch (error) {
    console.warn('Could not retrieve Meta account for report:', error.message);
    return { accountName: 'Connected ad account', unavailable: true };
  }
}

async function getAdMetrics(context) {
  if (context.unavailable) return { available: false };
  try {
    let raw = null;
    let periodUsed = 'Last 30 Days';

    // 1. Try last_30d first
    try {
      const res30 = await axios.get(`${META_GRAPH_BASE_URL}/${context.id}/insights`, {
        params: {
          date_preset: 'last_30d',
          fields: 'spend,impressions,reach,clicks,ctr,cpc,frequency,actions,action_values',
          access_token: context.token
        },
        timeout: 8000
      });
      raw = res30.data?.data?.[0];
    } catch (_) {}

    // 2. If last_30d has no ad delivery data, fall back to maximum (Lifetime / All-time)
    if (!raw) {
      try {
        const resMax = await axios.get(`${META_GRAPH_BASE_URL}/${context.id}/insights`, {
          params: {
            date_preset: 'maximum',
            fields: 'spend,impressions,reach,clicks,ctr,cpc,frequency,actions,action_values',
            access_token: context.token
          },
          timeout: 8000
        });
        raw = resMax.data?.data?.[0];
        if (raw) periodUsed = 'Lifetime Campaign Delivery';
      } catch (_) {}
    }

    if (!raw) return { available: false };

    const action = (type, values = raw.actions) => number(values?.find(item => item.action_type === type)?.value);
    const spend = number(raw.spend);
    const impressions = number(raw.impressions);
    const reach = number(raw.reach);
    const clicks = number(raw.clicks);
    const ctr = number(raw.ctr);
    const cpc = number(raw.cpc);
    const frequency = number(raw.frequency) || (reach ? impressions / reach : 1);
    const leads = action('lead') + action('onsite_conversion.lead_grouped') + action('leadgen.other');
    const purchaseValue = action('purchase', raw.action_values);

    return {
      available: true,
      periodUsed,
      spend,
      impressions,
      reach,
      clicks,
      ctr,
      cpc,
      frequency,
      leads,
      purchaseValue,
      currency: context.currency || 'INR'
    };
  } catch (error) {
    console.warn('Could not retrieve Meta insights for report:', error.message);
    return { available: false };
  }
}

async function getLocalMetrics(userId, pageId, formId) {
  const since = new Date();
  since.setDate(since.getDate() - 30);

  let leadWhere = { userId };
  let selectedPageName = 'All Connected Pages';

  // If a specific formId is specified
  if (formId && formId !== 'all') {
    leadWhere.formId = formId;
  } else if (pageId && pageId !== 'all') {
    const pageAccount = await SocialAccount.findOne({ where: { userId, accountId: pageId, platform: 'facebook' } });
    if (pageAccount) {
      selectedPageName = pageAccount.accountName;
      try {
        const formsRes = await axios.get(`${META_GRAPH_BASE_URL}/${pageId}/leadgen_forms`, {
          params: { fields: 'id,name,status', access_token: pageAccount.accessToken },
          timeout: 6000
        });
        const forms = formsRes.data?.data || [];
        const formIds = forms.map(f => f.id);

        // Auto-sync leads from Meta for these forms
        for (const form of forms) {
          try {
            const leadsRes = await axios.get(`${META_GRAPH_BASE_URL}/${form.id}/leads`, {
              params: { fields: 'id,created_time,field_data', access_token: pageAccount.accessToken, limit: 100 },
              timeout: 6000
            });
            const metaLeads = leadsRes.data?.data || [];
            for (const ml of metaLeads) {
              let name = '', email = '', phone = '';
              if (ml.field_data) {
                ml.field_data.forEach(field => {
                  const fn = (field.name || '').toLowerCase();
                  const val = field.values?.[0] || '';
                  if (fn.includes('name')) name = val;
                  else if (fn.includes('email')) email = val;
                  else if (fn.includes('phone') || fn.includes('mobile')) phone = val;
                });
              }
              await Lead.findOrCreate({
                where: { id: ml.id },
                defaults: {
                  userId,
                  formId: form.id,
                  name: name || 'Lead',
                  email: email || 'N/A',
                  phone: phone || 'N/A',
                  status: 'New',
                  submittedAt: ml.created_time ? new Date(ml.created_time) : new Date()
                }
              });
            }
          } catch (_) {}
        }

        if (formIds.length > 0) {
          leadWhere.formId = formIds;
        } else {
          leadWhere.formId = '__NO_FORMS_ON_PAGE__';
        }
      } catch (err) {
        console.warn(`Could not query forms for page ${pageId}:`, err.message);
      }
    }
  }

  const [leads, posts] = await Promise.all([
    Lead.findAll({ where: leadWhere, order: [['submittedAt', 'DESC']] }),
    ScheduledPost.findAll({ where: { userId }, order: [['scheduledTime', 'DESC']] })
  ]);

  const leadMetrics = {
    total: leads.length,
    new: 0,
    contacted: 0,
    converted: 0,
    last30: 0,
    missingContact: 0,
    selectedPageName
  };

  leads.forEach(lead => {
    const status = String(lead.status || '').toLowerCase();
    if (status === 'new') leadMetrics.new++;
    if (status === 'contacted') leadMetrics.contacted++;
    if (status === 'converted') leadMetrics.converted++;
    if (lead.submittedAt && new Date(lead.submittedAt) >= since) leadMetrics.last30++;
    if (!lead.email && !lead.phone) leadMetrics.missingContact++;
  });

  const postMetrics = { total: posts.length, pending: 0, published: 0, failed: 0, upcoming: 0 };
  posts.forEach(post => {
    const status = String(post.status || '').toLowerCase();
    if (Object.hasOwn(postMetrics, status)) postMetrics[status]++;
    if (status === 'pending' && new Date(post.scheduledTime) >= new Date()) postMetrics.upcoming++;
  });

  return { leads, posts, leadMetrics, postMetrics, selectedPageName };
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

async function getSocialPerformance(userId, socialAccountId, requestedPeriod) {
  const accounts = await getSocialAccounts(userId);
  const selected = accounts.find(account => account.id === socialAccountId) || accounts[0];
  if (!selected) return { available: false, accounts, reason: 'Connect a Facebook Page or Instagram professional account to view live social insights.' };
  const account = await SocialAccount.findOne({ where: { userId, accountId: selected.id, platform: selected.platform } });
  const days = socialPeriodDays(requestedPeriod);
  const isFacebook = selected.platform === 'facebook';

  let profile = {};
  let rawPosts = [];
  let insights = { data: [] };
  let hasInsights = false;
  let hasContent = false;

  // 1. Fetch Profile Info
  try {
    const profileRes = await axios.get(`${META_GRAPH_BASE_URL}/${selected.id}`, {
      params: {
        access_token: account.accessToken,
        fields: isFacebook ? 'id,name,followers_count,fan_count' : 'id,username,followers_count,media_count'
      },
      timeout: 8000
    });
    profile = profileRes.data || {};
  } catch (e) {
    console.warn('Profile fetch error:', e.message);
  }

  // 2. Fetch Posts / Media
  try {
    if (isFacebook) {
      let fbRes;
      try {
        fbRes = await axios.get(`${META_GRAPH_BASE_URL}/${selected.id}/published_posts`, {
          params: {
            access_token: account.accessToken,
            fields: 'id,message,story,created_time,permalink_url,shares,reactions.summary(true),comments.summary(true)',
            limit: 20
          },
          timeout: 8000
        });
      } catch (_) {
        fbRes = await axios.get(`${META_GRAPH_BASE_URL}/${selected.id}/posts`, {
          params: {
            access_token: account.accessToken,
            fields: 'id,message,story,created_time,permalink_url,shares,reactions.summary(true),comments.summary(true)',
            limit: 20
          },
          timeout: 8000
        });
      }
      rawPosts = fbRes.data?.data || [];
    } else {
      const igRes = await axios.get(`${META_GRAPH_BASE_URL}/${selected.id}/media`, {
        params: {
          access_token: account.accessToken,
          fields: 'id,caption,media_type,media_url,permalink,timestamp,like_count,comments_count',
          limit: 20
        },
        timeout: 8000
      });
      rawPosts = igRes.data?.data || [];
    }
    if (rawPosts.length > 0) hasContent = true;
  } catch (e) {
    console.warn('Content fetch error:', e.message);
  }

  // 3. Fetch Page/IG Level Insights
  try {
    const insightRes = await axios.get(`${META_GRAPH_BASE_URL}/${selected.id}/insights`, {
      params: {
        access_token: account.accessToken,
        period: 'day',
        metric: isFacebook ? 'page_impressions_unique,page_post_engagements' : 'reach,accounts_engaged,total_interactions,profile_views'
      },
      timeout: 8000
    });
    insights = insightRes.data || { data: [] };
    hasInsights = true;
  } catch (e) {
    console.warn('Insights fetch error:', e.message);
  }

  // 4. Map & Format Top Posts with verified text & engagement
  const topPosts = rawPosts.map(post => {
    let reactions = 0;
    let comments = 0;
    let shares = number(post.shares?.count);

    if (isFacebook) {
      reactions = number(post.reactions?.summary?.total_count);
      comments = number(post.comments?.summary?.total_count);
    } else {
      reactions = number(post.like_count);
      comments = number(post.comments_count);
    }

    const rawText = isFacebook
      ? (post.message || post.story || 'Facebook Media Update')
      : (post.caption || 'Instagram Media Update');

    const cleanText = rawText.trim().replace(/\s+/g, ' ');

    return {
      id: post.id,
      text: cleanText.length > 0 ? cleanText : `${isFacebook ? 'Facebook' : 'Instagram'} Media Post`,
      permalink: post.permalink_url || post.permalink,
      createdAt: post.created_time || post.timestamp,
      reactions,
      comments,
      shares,
      engagement: reactions + comments + shares
    };
  }).sort((a, b) => b.engagement - a.engagement).slice(0, 5);

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
    followers: number(profile.followers_count || profile.fan_count),
    source: isFacebook ? 'Facebook Page' : 'Instagram Professional',
    fetchedAt: new Date().toISOString()
  };
}

async function buildReport(type, userId, adAccountId, socialAccountId, requestedPeriod, pageId, formId) {
  const [user, local, context, fbPages] = await Promise.all([
    User.findByPk(userId),
    getLocalMetrics(userId, pageId, formId),
    getMetaContext(userId, adAccountId),
    getFacebookPages(userId)
  ]);

  const business = user?.businessName || 'Your business';
  const leads = local.leadMetrics;
  const posts = local.postMetrics;
  let summary = '';
  let metrics = [];
  let insights = [];
  let actions = [];
  let dataStatus = 'Based on your synced account data.';
  let period = 'Last 30 Days';

  if (type === 'leads') {
    const rate = percent(leads.converted, leads.total);
    const pageLabel = leads.selectedPageName ? ` (${leads.selectedPageName})` : '';
    period = `All-time synced leads${pageLabel}`;
    summary = leads.total
      ? `${business}${pageLabel} has ${leads.total} captured leads in the pipeline. ${leads.converted} have converted to customers (${rate}% conversion rate). ${leads.new} leads are newly received and require follow-up.`
      : `No leads found for ${business}${pageLabel}. Connect a Facebook Lead Form or select another connected Page to sync new inquiries.`;

    metrics = [
      metric('Total Leads', leads.total, `${leads.last30} received in last 30 days`),
      metric('Conversion Rate', `${rate}%`, `${leads.converted} converted leads`, rate >= 10 ? 'positive' : 'neutral'),
      metric('Needs Follow-up', leads.new, 'Awaiting initial contact', leads.new ? 'attention' : 'positive'),
      metric('In Progress', leads.contacted, 'Currently contacted')
    ];

    insights = [
      leads.total ? `${leads.converted} out of ${leads.total} leads (${rate}%) have successfully converted.` : 'Connect a Facebook Lead Form to start receiving verified customer leads.',
      leads.new ? `${percent(leads.new, leads.total)}% of your pipeline is currently marked 'New' and awaiting outreach.` : 'Great job! All current leads have been contacted or processed.',
      leads.missingContact ? `Notice: ${leads.missingContact} lead(s) are missing phone or email details.` : '100% of synced leads have valid contact details.'
    ];

    actions = [
      leads.new ? `Follow up immediately with the ${leads.new} new lead${leads.new === 1 ? '' : 's'} via WhatsApp/Call to maximize conversion chances.` : 'Review lead qualification questions in Meta Instant Forms to improve contact response rate.',
      leads.contacted ? `Move contacted leads to 'Converted' status as soon as deals close to keep funnel metrics accurate.` : 'Set up automated instant notifications for incoming lead form submissions.'
    ];

    return {
      context,
      local,
      report: {
        title: TITLES[type],
        date: today(),
        period,
        generatedAt: new Date().toISOString(),
        summary,
        metrics,
        insights,
        actions,
        dataStatus,
        facebookPages: fbPages,
        selectedPageId: pageId || 'all',
        selectedPageName: leads.selectedPageName
      }
    };

  } else if (type === 'social') {
    const performance = await getSocialPerformance(userId, socialAccountId, requestedPeriod);
    period = `Last ${performance.days || socialPeriodDays(requestedPeriod)} days • ${performance.source || 'Social activity'}`;
    if (!performance.available) {
      dataStatus = performance.reason || 'Live social insights are unavailable.';
      summary = posts.total ? `${posts.total} posts are in your publishing workflow, but live social metrics could not be retrieved from Meta.` : 'No live social insights are available yet.';
      metrics = [
        metric('Posts in Workflow', posts.total, `${posts.published} published`),
        metric('Upcoming Posts', posts.upcoming, 'Scheduled in calendar', posts.upcoming ? 'positive' : 'attention'),
        metric('Failed Posts', posts.failed, 'Require review or rescheduling', posts.failed ? 'attention' : 'positive')
      ];
      insights = ['Connect a Facebook Page or Instagram Business account with insights permissions to view engagement trends.'];
      actions = ['Reconnect your social account in Social Accounts settings to grant insights access, then refresh this report.'];
    } else {
      const top = performance.topPosts[0];
      dataStatus = performance.hasInsights
        ? `Live ${performance.source} data fetched from Meta at ${new Date(performance.fetchedAt).toLocaleTimeString()}.`
        : `Live posts were fetched from Meta, but account-level insights were not authorized.`;
      summary = performance.hasInsights
        ? `${performance.selected.name} generated ${performance.reach.toLocaleString()} reach and ${performance.engagement.toLocaleString()} interactions over the last ${performance.days} days.`
        : `${performance.selected.name} has ${performance.topPosts.length} live post${performance.topPosts.length === 1 ? '' : 's'} on Meta.`;
      metrics = performance.hasInsights
        ? [
            metric('Reach', performance.reach.toLocaleString(), `Meta-reported daily total • ${performance.days} days`),
            metric('Interactions', performance.engagement.toLocaleString(), performance.selected.platform === 'instagram' ? `${performance.engagedAccounts.toLocaleString()} engaged accounts` : 'Page post engagement'),
            metric('Followers', performance.followers.toLocaleString(), performance.selected.platform === 'instagram' ? 'Instagram Business Account' : 'Facebook Page'),
            metric('Top Posts', performance.topPosts.length, 'Ranked by visible engagement')
          ]
        : [
            metric('Live Posts', performance.topPosts.length, `Fetched from ${performance.selected.name}`),
            metric('Followers', performance.followers.toLocaleString(), 'Live account profile data'),
            metric('Account Insights', 'Unavailable', 'Meta did not authorize this request', 'attention')
          ];
      insights = [
        top ? `Top content: “${top.text.slice(0, 80)}${top.text.length > 80 ? '…' : ''}” with ${top.engagement} visible interactions.` : 'No posts were returned by Meta for the selected period.',
        posts.upcoming ? `${posts.upcoming} post${posts.upcoming === 1 ? ' is' : 's are'} scheduled in your upcoming queue.` : 'There are no upcoming scheduled posts in the queue.'
      ];
      actions = [
        top ? 'Replicate the format and hook angle of your top-performing post in new campaign variations.' : 'Maintain a consistent 3-4 posts/week schedule to boost organic Meta algorithm distribution.',
        posts.failed ? `Resolve ${posts.failed} failed scheduled post${posts.failed === 1 ? '' : 's'} in Social Scheduler.` : 'Experiment with short-form Reels to expand reach beyond your existing followers.'
      ];
    }
    return {
      context,
      local,
      report: {
        title: TITLES[type],
        date: today(),
        period,
        generatedAt: new Date().toISOString(),
        summary,
        metrics,
        insights,
        actions,
        dataStatus,
        socialAccounts: performance.accounts,
        selectedSocialAccountId: performance.selected?.id,
        selectedSocialAccountName: performance.selected?.name,
        selectedSocialAccountPlatform: performance.selected?.platform,
        topPosts: performance.topPosts || []
      }
    };

  } else if (type === 'ads') {
    const ads = await getAdMetrics(context);
    period = ads.available ? ads.periodUsed : 'Last 30 Days (No Activity)';
    if (!ads.available) {
      dataStatus = 'No active Meta ad campaigns found for this ad account.';
      summary = `No delivery data was returned for ${context.accountName || 'this ad account'}. Connect your active Meta ad account in Settings to populate live spend, reach, CTR, and lead acquisition metrics.`;
      metrics = [
        metric('Ad Spend', `${context.currency || 'INR'} 0`, 'No spend recorded'),
        metric('Impressions', '0', 'Meta ad delivery'),
        metric('Link Clicks', '0', 'Traffic engagement'),
        metric('CTR', '0.00%', 'Click-through rate')
      ];
      insights = [
        'Live Meta ad delivery insights require active or past campaigns with running ads.',
        'Connecting your active ad account unlocks real-time CPM, CTR, Frequency, and Cost-per-Lead tracking.'
      ];
      actions = [
        'Select an ad account that has active or past campaigns from the dropdown above.',
        'Verify that your ad campaigns are active in Meta Ads Manager.'
      ];
    } else {
      summary = `${business} spent ${ads.currency} ${ads.spend.toLocaleString('en-IN', { minimumFractionDigits: 2 })} on Meta ads (${ads.periodUsed}), generating ${ads.impressions.toLocaleString()} impressions, ${ads.reach.toLocaleString()} unique reach, and ${ads.clicks.toLocaleString()} link clicks (${ads.ctr.toFixed(2)}% CTR).`;
      metrics = [
        metric('Total Spend', `${ads.currency} ${ads.spend.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`, ads.periodUsed),
        metric('CTR', `${ads.ctr.toFixed(2)}%`, `${ads.clicks.toLocaleString()} link clicks`, ads.ctr >= 1 ? 'positive' : 'attention'),
        metric('Cost Per Click', `${ads.currency} ${ads.cpc.toFixed(2)}`, `${ads.impressions.toLocaleString()} impressions`),
        metric('Meta Leads', ads.leads, ads.leads > 0 ? `${ads.currency} ${(ads.spend / ads.leads).toFixed(2)} / lead` : 'No lead actions reported')
      ];
      insights = [
        `Average frequency is ${ads.frequency.toFixed(2)} impressions per reached user (${ads.frequency > 3 ? 'Caution: Ad creative fatigue risk' : 'Healthy ad exposure rate'}).`,
        ads.leads ? `Meta-reported Cost Per Lead (CPL) is ${ads.currency} ${(ads.spend / ads.leads).toFixed(2)} across all campaigns.` : 'No Meta Lead actions were reported during this campaign window.',
        ads.ctr >= 1 ? `CTR of ${ads.ctr.toFixed(2)}% outperforms the industry benchmark of 0.90%.` : `CTR of ${ads.ctr.toFixed(2)}% is below 1.0%; test punchier visual hooks to improve engagement.`
      ];
      actions = [
        ads.ctr < 1 ? 'Test 3 new high-contrast video/carousel hooks to drive CTR above 1.2%.' : 'Scale budget on top-performing ad sets by 15-20% while monitoring frequency.',
        ads.frequency > 3 ? 'Refresh ad creatives or expand audience targeting size to reduce ad fatigue.' : 'Keep current targeting intact and test lookalike audiences.'
      ];
    }

  } else {
    // ROI & Funnel Report
    const ads = await getAdMetrics(context);
    const roas = ads.available && ads.spend > 0 && ads.purchaseValue ? ads.purchaseValue / ads.spend : null;
    const cpl = ads.available && ads.spend > 0 && (ads.leads || leads.total) ? (ads.spend / (ads.leads || leads.total)).toFixed(2) : null;
    const cac = ads.available && ads.spend > 0 && leads.converted > 0 ? (ads.spend / leads.converted).toFixed(2) : null;
    const convRate = percent(leads.converted, leads.total);

    period = ads.available ? `${ads.periodUsed} • Paid Media & Funnel ROI` : 'Local Pipeline Snapshot';
    summary = ads.available
      ? `ROI & Acquisition Overview for ${business}: Tracked ad spend is ${ads.currency} ${ads.spend.toLocaleString('en-IN', { minimumFractionDigits: 2 })}, with ${leads.total} total synced leads and ${leads.converted} converted customers (${convRate}% pipeline conversion).`
      : `ROI & Acquisition Overview for ${business}: No ad spend recorded for this ad account. Pipeline has ${leads.total} synced leads and ${leads.converted} converted customers (${convRate}% conversion rate).`;

    metrics = [
      metric('Tracked Ad Spend', ads.available ? `${ads.currency} ${ads.spend.toLocaleString('en-IN', { minimumFractionDigits: 2 })}` : `${context.currency || 'INR'} 0`, ads.available ? ads.periodUsed : 'No ad spend recorded'),
      metric('Cost Per Lead (CPL)', cpl ? `${ads.currency} ${cpl}` : '—', cpl ? 'Based on tracked spend' : 'Requires active ad spend'),
      metric('Customer CAC', cac ? `${ads.currency} ${cac}` : '—', cac ? `${leads.converted} converted customers` : 'No converted sales yet'),
      metric('Pipeline Conversion', `${convRate}%`, `${leads.converted} of ${leads.total} converted`, convRate >= 10 ? 'positive' : 'neutral')
    ];

    insights = [
      cpl ? `Average acquisition cost per inquiry is ${ads.currency} ${cpl}.` : 'Connect active Meta Ad spend to calculate exact Cost Per Lead (CPL).',
      cac ? `Customer Acquisition Cost (CAC) is ${ads.currency} ${cac} per paying customer.` : 'Mark contacted leads as "Converted" to measure real Customer Acquisition Cost.',
      roas ? `Return on Ad Spend (ROAS) is ${roas.toFixed(2)}x based on Meta tracked purchase values.` : 'Enable purchase conversion tracking with Meta Pixel/CAPI to calculate automated ROAS.'
    ];

    actions = [
      leads.new ? `Prioritize prompt follow-ups with ${leads.new} new inquiries; speeding up response times lowers effective CAC by 30-50%.` : 'Maintain high conversion speed to protect paid-media margins.',
      'Configure Meta Pixel / Conversions API purchase events to unlock automated real-time ROAS reporting.',
      'Reallocate ad budget from high-CPL campaigns into your top-converting lead magnets.'
    ];
  }

  return {
    context,
    local,
    report: {
      title: TITLES[type],
      date: today(),
      period,
      generatedAt: new Date().toISOString(),
      summary,
      metrics,
      insights,
      actions,
      dataStatus,
      facebookPages: fbPages
    }
  };
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

    const items = [
      ['ads', 'Ads', 'campaign_outlined', 'Live Meta spend, delivery, CTR and link click performance across your ad accounts.'],
      ['leads', 'Leads', 'people_outline_rounded', `${leads} synced inquiries with page-level filtering, conversion rate, and follow-up metrics.`],
      ['roi', 'ROI', 'show_chart_rounded', 'Paid media acquisition costs (CPL, CAC), pipeline conversion, and ROAS readiness.'],
      ['social', 'Social', 'post_add_outlined', 'Live Facebook & Instagram insights, engagement rate, and top-performing content.']
    ];

    res.json({
      success: true,
      accountName: context.accountName,
      reports: items.map(([id, category, iconName, description]) => ({
        id,
        title: TITLES[id],
        category,
        iconName,
        description,
        date: today()
      }))
    });
  } catch (error) {
    console.error('Error listing reports:', error.message);
    res.status(500).json({ success: false, error: 'Internal Server Error' });
  }
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
  if (!VALID_TYPES.has(req.params.type)) {
    return res.status(400).json({ success: false, error: 'Unknown report type.' });
  }
  try {
    let adAccountId = req.query.adAccountId;
    const output = await buildReport(
      req.params.type,
      req.user.id,
      adAccountId,
      req.query.socialAccountId,
      req.query.period,
      req.query.pageId,
      req.query.formId
    );
    res.json({ success: true, accountName: output.context.accountName, report: output.report });
  } catch (error) {
    console.error('Error fetching report details:', error.message);
    res.status(500).json({ success: false, error: 'Internal Server Error' });
  }
};

exports.downloadReport = async (req, res) => {
  if (!VALID_TYPES.has(req.params.type)) {
    return res.status(400).json({ success: false, error: 'Unknown report type.' });
  }
  try {
    let adAccountId = req.query.adAccountId;
    const { report, context, local } = await buildReport(
      req.params.type,
      req.user.id,
      adAccountId,
      req.query.socialAccountId,
      req.query.period,
      req.query.pageId,
      req.query.formId
    );

    let csv = '\ufeff';
    csv += toCsvRow(['==================================================']);
    csv += toCsvRow(['            MARKET AI PERFORMANCE REPORT          ']);
    csv += toCsvRow(['==================================================']);
    csv += toCsvRow(['Report Title', report.title]);
    csv += toCsvRow(['Meta Ad Account', context.accountName]);
    if (report.selectedPageName) {
      csv += toCsvRow(['Facebook Page', report.selectedPageName]);
    }
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
      csv += toCsvRow(['Lead ID', 'Name', 'Email', 'Phone', 'Status', 'Submitted At']);
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
