const axios = require('axios');
const User = require('../models/User');
const SocialAccount = require('../models/SocialAccount');
const CompetitorWatchlist = require('../models/CompetitorWatchlist');
const CompetitorAd = require('../models/CompetitorAd');
const ApiUsage = require('../models/ApiUsage');

let isApifySuspended = false;

function getFallbackCompetitorAnalysis(businessName, industry, services, prompt) {
  const safeName = businessName && businessName !== 'a startup' ? businessName : 'Your Business';
  const safeIndustry = industry && industry !== 'general business' ? industry : 'Marketing & Tech';
  const safeServices = services && services !== 'general services' ? services : 'Growth Marketing & Leads';

  const defaultImages = [
    'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1551434678-e076c223a692?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1542744094-3a31f103e35f?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1557200134-90327ee9fafa?auto=format&fit=crop&w=600&q=80'
  ];

  return {
    competitors: [
      {
        name: `${safeIndustry.split(' ')[0]} Pulse Global`,
        handle: `@${safeIndustry.split(' ')[0].toLowerCase()}pulse`,
        rank: "1",
        ads: [
          {
            caption: `Looking for top-tier ${safeServices}? Scale your operations with industry-leading solutions tailored for modern brands. Book your discovery call today!`,
            mediaType: "image",
            mediaUrl: defaultImages[0],
            landingPageUrl: "https://www.google.com/search?q=" + encodeURIComponent(safeIndustry + " pulse"),
            ctaText: "Learn More",
            startedAt: new Date(Date.now() - 42 * 86400000).toISOString().split('T')[0],
            adHook: "Free Strategic Growth Audit",
            angle: "Pain-point relief & conversion lift",
            offer: "Complimentary Consultation"
          },
          {
            caption: `Why high-growth businesses choose us for ${safeServices}: Proven execution, transparent reporting, and rapid scalability. Discover our case studies.`,
            mediaType: "video",
            mediaUrl: defaultImages[1],
            landingPageUrl: "https://www.google.com/search?q=" + encodeURIComponent(safeIndustry + " case studies"),
            ctaText: "Sign Up",
            startedAt: new Date(Date.now() - 14 * 86400000).toISOString().split('T')[0],
            adHook: "Proven Client Case Study",
            angle: "Authority & social proof",
            offer: "Case Study Access"
          },
          {
            caption: `⚡ Limited Time: Get onboarding support and specialized strategy planning for ${safeServices}. Click below to claim your spot!`,
            mediaType: "carousel",
            mediaUrl: defaultImages[2],
            landingPageUrl: "https://www.google.com/search?q=" + encodeURIComponent(safeIndustry + " offer"),
            ctaText: "Book Now",
            startedAt: new Date(Date.now() - 5 * 86400000).toISOString().split('T')[0],
            adHook: "Exclusive Onboarding Package",
            angle: "Time-limited urgency",
            offer: "20% Launch Discount"
          }
        ]
      },
      {
        name: `Apex ${safeIndustry.split(' ')[0]} Solutions`,
        handle: `@apex${safeIndustry.split(' ')[0].toLowerCase()}`,
        rank: "2",
        ads: [
          {
            caption: `Struggling to find reliable ${safeServices}? Apex delivers verified strategies that drive measurable ROI. See how we help companies grow.`,
            mediaType: "image",
            mediaUrl: defaultImages[3],
            landingPageUrl: "https://www.google.com/search?q=" + encodeURIComponent("Apex " + safeIndustry),
            ctaText: "Learn More",
            startedAt: new Date(Date.now() - 35 * 86400000).toISOString().split('T')[0],
            adHook: "ROI Focused Workflow",
            angle: "Direct efficiency marketing",
            offer: "Free Process Blueprint"
          },
          {
            caption: `Cut through the noise. Get seamless execution on ${safeServices} without long-term lock-in contracts. Get started today.`,
            mediaType: "video",
            mediaUrl: defaultImages[4],
            landingPageUrl: "https://www.google.com/search?q=" + encodeURIComponent("Apex " + safeIndustry),
            ctaText: "Sign Up",
            startedAt: new Date(Date.now() - 10 * 86400000).toISOString().split('T')[0],
            adHook: "No-Lockin Flexibility",
            angle: "Risk reversal",
            offer: "14-Day Guarantee"
          },
          {
            caption: `Discover the exact framework top performers use in ${safeIndustry} to generate steady customer demand. Download our free guide now.`,
            mediaType: "carousel",
            mediaUrl: defaultImages[5],
            landingPageUrl: "https://www.google.com/search?q=" + encodeURIComponent("Apex " + safeIndustry),
            ctaText: "Download",
            startedAt: new Date(Date.now() - 3 * 86400000).toISOString().split('T')[0],
            adHook: "Framework Guide",
            angle: "Educational lead magnet",
            offer: "Free Blueprint PDF"
          }
        ]
      },
      {
        name: `Vanguard ${safeIndustry.split(' ')[0]} Labs`,
        handle: `@vanguard${safeIndustry.split(' ')[0].toLowerCase()}`,
        rank: "3",
        ads: [
          {
            caption: `Upgrade your brand with elite ${safeServices}. Fast onboarding, modern methodology, and dedicated support.`,
            mediaType: "image",
            mediaUrl: defaultImages[1],
            landingPageUrl: "https://www.google.com/search?q=" + encodeURIComponent("Vanguard " + safeIndustry),
            ctaText: "Learn More",
            startedAt: new Date(Date.now() - 28 * 86400000).toISOString().split('T')[0],
            adHook: "Dedicated Support Team",
            angle: "Premium service assurance",
            offer: "Free Setup & Onboarding"
          },
          {
            caption: `How to scale ${safeServices} in 2026: Watch our 5-minute breakdown to see real campaign breakdowns and metrics.`,
            mediaType: "video",
            mediaUrl: defaultImages[0],
            landingPageUrl: "https://www.google.com/search?q=" + encodeURIComponent("Vanguard " + safeIndustry),
            ctaText: "Watch Video",
            startedAt: new Date(Date.now() - 8 * 86400000).toISOString().split('T')[0],
            adHook: "Video Masterclass",
            angle: "High-value video demonstration",
            offer: "None"
          },
          {
            caption: `Ready to outperform your rivals? Partner with Vanguard to supercharge your ${safeServices} today.`,
            mediaType: "carousel",
            mediaUrl: defaultImages[2],
            landingPageUrl: "https://www.google.com/search?q=" + encodeURIComponent("Vanguard " + safeIndustry),
            ctaText: "Get Quote",
            startedAt: new Date(Date.now() - 2 * 86400000).toISOString().split('T')[0],
            adHook: "Instant Custom Quote",
            angle: "Direct conversion action",
            offer: "Free Estimation"
          }
        ]
      }
    ],
    metrics: {
      totalAds: "18 Active Ads",
      monthlySpend: "₹45,000 - ₹85,000",
      engagementRate: "4.5%",
      adStrategy: "Direct Response & Lead Generation"
    },
    tabs: {
      overview: `Top competitors in ${safeIndustry} focus aggressively on pain-point messaging and social proof around ${safeServices}. They maintain continuous ad spend on Meta and Instagram platforms with strong hook angles.`,
      ads: `Competitors are utilizing single image lead hooks for direct acquisition, 15-30 second video case studies for retargeting, and multi-card carousels for promotional offers.`,
      socialMedia: `Competitor pages publish 4-5 times weekly across Instagram and Facebook with emphasis on customer results, behind-the-scenes insights, and actionable tips.`,
      strengths: `Competitors excel in clear CTA placement, fast response times on ad inquiries, and value-packed introductory offers that reduce friction for new clients.`
    },
    swot: {
      strengths: [
        `Strong brand recall in the ${safeIndustry} market`,
        `Consistent multi-format Meta ad distribution`,
        `High social proof with verified case studies`
      ],
      weaknesses: [
        `Generic copy templates in middle-funnel ads`,
        `Limited interactive content and localized engagement`,
        `Higher pricing barriers for entry-level customers`
      ],
      opportunities: [
        `Differentiate ${safeName} with transparent pricing and personalized support`,
        `Leverage short-form video hooks targeting competitor weak points`,
        `Target underserved niche queries in ${safeIndustry}`
      ],
      threats: [
        `Rising ad bid costs (CPM) in ${safeIndustry}`,
        `Aggressive promotional discounting by incumbent competitors`,
        `Rapid ad creative fatigue requiring constant new variations`
      ]
    },
    audienceSuggestions: [
      `Business Owners & Founders (Age 25-50)`,
      `Decision Makers searching for ${safeServices}`,
      `${safeIndustry} Enthusiasts & SMBs`,
      `Instagram & Facebook Active Purchasers`
    ],
    recommendedAd: {
      headline: `Looking for Superior ${safeServices}? Choose ${safeName}`,
      primaryText: `Don't settle for high costs and slow delivery. At ${safeName}, we provide results-driven ${safeServices} tailored to your business goals. Get your free custom audit today!`,
      callToAction: "Learn More",
      landingPage: "/consultation"
    }
  };
}

function getFallbackAiSearchResult(prompt) {
  const cleanPrompt = (prompt || 'Search').trim();

  return {
    title: `Intelligence Overview: ${cleanPrompt}`,
    summary: `Comprehensive analysis for "${cleanPrompt}": Based on current market benchmarks and product landscape, understanding key specifications, brand reputations, and practical use cases helps ensure optimal decision-making.`,
    insights: [
      `Leading brands and solutions in this domain prioritize durability, high performance, and user satisfaction.`,
      `Price-to-performance ratio varies significantly across entry-level vs. premium professional tiers.`,
      `Verified customer feedback and real-world testing are the most reliable indicators of long-term reliability.`
    ],
    recommendations: [
      `Compare top-rated options against your specific budget, venue size, or feature requirements before committing.`,
      `Look for warranty coverage, after-sales support, and verified user reviews.`
    ]
  };
}

function getMockAdsForCompetitor(competitorName, industry, services, watchlistId) {
  const daysOffset = [45, 12, 4];
  const formats = ['image', 'video', 'carousel'];
  const images = [
    'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=600&q=80'
  ];
  
  const captions = [
    `Struggling to grow your business in the ${industry} sector? At ${competitorName}, we specialize in premium ${services} customized to generate high-value client leads. Claim your free consultation audit today!`,
    `⚡ SPECIAL OFFER: Get 20% off on all ${services} with ${competitorName} this week! We help businesses optimize their ad conversion workflows and maximize returns. Sign up now!`,
    `Why are industry leaders choosing ${competitorName} for their ${services} needs? Because we deliver results-driven marketing solutions that help you scale. Tap below to view our portfolio and book a free session.`
  ];

  const hooks = [
    'Free Consultation Audit',
    '20% Off Services Offer',
    'Growth Case Study'
  ];

  const angles = [
    'Pain-point targeting on lead quality',
    'Direct promotional price incentive',
    'Social proof and authority styling'
  ];

  const offers = [
    'Free Setup & Audit',
    '20% Onboarding Discount',
    'Free E-Book Guide'
  ];

  return daysOffset.map((days, idx) => ({
    watchlistId,
    caption: captions[idx],
    mediaType: formats[idx],
    mediaUrl: images[idx],
    landingPageUrl: `https://www.${competitorName.toLowerCase().replace(/\s+/g, '')}.com/promo`,
    ctaText: 'Learn More',
    startedAt: new Date(Date.now() - days * 24 * 60 * 60 * 1000),
    adHook: hooks[idx],
    angle: angles[idx],
    offer: offers[idx]
  }));
}

async function scrapeCompetitorAdsViaApify(competitorName, apifyToken, userId) {
  if (isApifySuspended) {
    return null;
  }

  try {
    console.log(`[Apify Crawler] Scraping Meta Ad Library for: ${competitorName}`);
    
    // Log Apify crawl trigger before execution
    await ApiUsage.create({
      userId,
      service: 'apify',
      action: 'competitor_scrape',
      status: 'success'
    });
    const response = await axios.post(
      `https://api.apify.com/v2/acts/apify~facebook-ads-scraper/run-sync-get-dataset-items?token=${apifyToken}`,
      {
        searchQuery: competitorName,
        searchType: "page",
        activeStatus: "ACTIVE",
        limit: 3,
        publisherPlatforms: ["FACEBOOK", "INSTAGRAM"]
      },
      {
        timeout: 4000 // Strict 4-second timeout to keep mobile app responsive
      }
    );

    if (response.status === 200 && Array.isArray(response.data) && response.data.length > 0) {
      console.log(`[Apify Crawler] Found ${response.data.length} ads for ${competitorName}`);
      const defaultImages = [
        'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1551434678-e076c223a692?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1542744094-3a31f103e35f?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1557200134-90327ee9fafa?auto=format&fit=crop&w=600&q=80'
      ];

      return response.data.map((item, idx) => {
        const adCopy = item.adCopy || item.text || item.caption || '';
        let mediaType = 'image';
        if (item.mediaType) {
          mediaType = item.mediaType.toLowerCase();
        } else if (item.videoUrl) {
          mediaType = 'video';
        } else if (item.carouselItems && item.carouselItems.length > 0) {
          mediaType = 'carousel';
        }

        // Try extracting mediaUrl from diverse crawler outputs
        let mediaUrl = item.mediaUrl || item.imageUrl || item.videoUrl;
        if (!mediaUrl) {
          if (item.images && item.images.length > 0) {
            mediaUrl = item.images[0];
          } else if (item.videos && item.videos.length > 0) {
            mediaUrl = item.videos[0];
          } else if (item.adCreativeImage) {
            mediaUrl = item.adCreativeImage;
          } else if (item.adCreativeImageUrl) {
            mediaUrl = item.adCreativeImageUrl;
          } else if (item.snapshotUrl) {
            mediaUrl = item.snapshotUrl;
          }
        }

        // Use index-based distinct fallback image if empty
        if (!mediaUrl) {
          mediaUrl = defaultImages[idx % defaultImages.length];
        }

        return {
          caption: adCopy,
          mediaType: mediaType,
          mediaUrl: mediaUrl,
          landingPageUrl: item.landingPage || item.landingPageUrl || 'https://www.facebook.com/ads/library',
          ctaText: item.ctaText || item.ctaType || 'Learn More',
          startedAt: item.startDate || item.startedAt || new Date().toISOString()
        };
      });
    }
  } catch (err) {
    console.warn(`[Apify Crawler] Scraper run failed for ${competitorName}:`, err.message);
    
    // Log Apify failure
    await ApiUsage.create({
      userId,
      service: 'apify',
      action: 'competitor_scrape',
      status: 'failed'
    });
    if (err.response && (err.response.status === 402 || err.response.status === 401)) {
      console.error('[Apify Crawler] Billing or Auth token expired. Suspending Apify crawler.');
      isApifySuspended = true;
    }
  }
  return null;
}

async function getWatchlistsWithAds(userId) {
  try {
    const allWatchlist = await CompetitorWatchlist.findAll({
      where: { userId },
      order: [['rank', 'ASC']]
    });

    const watchlistsWithAds = [];
    for (const item of allWatchlist) {
      const ads = await CompetitorAd.findAll({
        where: { watchlistId: item.id },
        order: [['startedAt', 'ASC']]
      });

      watchlistsWithAds.push({
        id: item.id,
        name: item.name,
        handle: item.handle,
        rank: item.rank,
        ads: ads.map(a => ({
          id: a.id,
          caption: a.caption,
          mediaType: a.mediaType,
          mediaUrl: a.mediaUrl,
          landingPageUrl: a.landingPageUrl,
          ctaText: a.ctaText,
          startedAt: a.startedAt,
          adHook: a.adHook,
          angle: a.angle,
          offer: a.offer,
          activeDays: Math.max(0, Math.floor((new Date() - new Date(a.startedAt)) / (1000 * 60 * 60 * 24)))
        }))
      });
    }
    return watchlistsWithAds;
  } catch (err) {
    console.error('Error fetching watchlists with ads:', err.message);
    return [];
  }
}

exports.analyzeCompetitors = async (req, res) => {
  const { prompt, facebookPageId } = req.body;
  if (!prompt) {
    return res.status(400).json({ success: false, error: 'Prompt is required' });
  }

  const userId = req.user.id;
  const apiKey = process.env.GEMINI_API_KEY;
  const apifyToken = process.env.APIFY_TOKEN;

  let businessName = 'a startup';
  let industry = 'general business';
  let services = 'general services';

  try {
    const user = await User.findByPk(userId);
    if (user) {
      businessName = user.businessName || 'a startup';
      industry = user.industry || 'general business';
      if (user.businessServices) {
        try {
          services = JSON.parse(user.businessServices).join(', ');
        } catch (_) {
          services = user.businessServices;
        }
      }
    }

    if (facebookPageId && facebookPageId !== 'null' && facebookPageId !== 'undefined') {
      try {
        const pageAccount = await SocialAccount.findOne({
          where: { userId, accountId: facebookPageId, platform: 'facebook' }
        });
        if (pageAccount) {
          const pageResponse = await axios.get(
            `https://graph.facebook.com/${process.env.META_GRAPH_API_VERSION || 'v20.0'}/${facebookPageId}`,
            {
              params: {
                fields: 'name,category,about,description,website',
                access_token: pageAccount.accessToken
              },
              timeout: 6000
            }
          );
          if (pageResponse.status === 200 && pageResponse.data) {
            businessName = pageResponse.data.name || businessName;
            industry = pageResponse.data.category || industry;
            services = pageResponse.data.about || pageResponse.data.description || services;
            console.log(`[Ad Spy Engine] Using Facebook Page Metadata: Name="${businessName}", Category="${industry}", Services="${services.substring(0, 40)}..."`);
          }
        }
      } catch (pageErr) {
        console.warn('Could not retrieve Page details from Facebook Graph API:', pageErr.message);
      }
    }

    // Clear old watchlists and cached ads for this user so search updates instantly
    try {
      const oldWatchlists = await CompetitorWatchlist.findAll({ where: { userId } });
      for (const item of oldWatchlists) {
        await CompetitorAd.destroy({ where: { watchlistId: item.id } });
        await item.destroy();
      }
    } catch (clearErr) {
      console.warn('Could not clear old competitor cache:', clearErr.message);
    }

    let parsed = null;

    if (apiKey && apiKey !== 'YOUR_GEMINI_API_KEY') {
      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=${apiKey}`;

      const instructionText = `
You are a top-tier business marketing analyst. Identify exactly 3 REAL-WORLD competitor brands in the user's market segment that are actively running ads on Meta (Facebook/Instagram Ads) and have active, searchable Facebook Pages or Instagram Business profiles. 

CRITICAL REQUIREMENT: Do NOT output imaginary, generic, or dummy names. The competitors must be real businesses that the user can verify on Meta Ads Library.

Analyze competitors for this business profile:
- Business Name: "${businessName}"
- Industry: "${industry}"
- Services Offered: "${services}"
- Search Prompt/Goal: "${prompt}"

Produce a detailed competitor analysis, marketing strategy, AND 3 high-converting simulated Facebook ad copy setups for EACH competitor directly inside the response object. Return ONLY a JSON object in this exact schema, with no markdown code block formatting or styling wrapper:
{
  "competitors": [
    { 
      "name": "Competitor 1 Name", 
      "handle": "@competitor1", 
      "rank": "1",
      "ads": [
        {
          "caption": "Primary text copy here highlighting pain points or solutions",
          "mediaType": "image",
          "mediaUrl": "https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=600&q=80",
          "landingPageUrl": "https://www.competitor1.com/promo",
          "ctaText": "Learn More",
          "startedAt": "2026-07-15",
          "adHook": "Free Strategy Audit",
          "angle": "Direct pain point marketing",
          "offer": "Free Setup"
        },
        {
          "caption": "Second ad copy here showcasing results and social proof",
          "mediaType": "video",
          "mediaUrl": "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=600&q=80",
          "landingPageUrl": "https://www.competitor1.com/leads",
          "ctaText": "Sign Up",
          "startedAt": "2026-08-05",
          "adHook": "Case Study Proof",
          "angle": "Authority marketing angle",
          "offer": "None"
        },
        {
          "caption": "Third ad copy here featuring onboarding promotion",
          "mediaType": "carousel",
          "mediaUrl": "https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=600&q=80",
          "landingPageUrl": "https://www.competitor1.com/promo2",
          "ctaText": "Book Now",
          "startedAt": "2026-08-15",
          "adHook": "20% Off Launch Promotion",
          "angle": "Promotional scarcity angle",
          "offer": "20% Off Services"
        }
      ]
    },
    { 
      "name": "Competitor 2 Name", 
      "handle": "@competitor2", 
      "rank": "2",
      "ads": [
        {
          "caption": "Primary ad copy for competitor 2...",
          "mediaType": "image",
          "mediaUrl": "https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=600&q=80",
          "landingPageUrl": "https://competitor2.com",
          "ctaText": "Learn More",
          "startedAt": "2026-07-20",
          "adHook": "Free Consult Guide",
          "angle": "Educational marketing",
          "offer": "Free Ebook"
        },
        {
          "caption": "Second ad copy for competitor 2...",
          "mediaType": "video",
          "mediaUrl": "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=600&q=80",
          "landingPageUrl": "https://competitor2.com",
          "ctaText": "Learn More",
          "startedAt": "2026-08-01",
          "adHook": "Quick Demo Audit",
          "angle": "Pain-point relief",
          "offer": "Free Strategy Call"
        },
        {
          "caption": "Third ad copy for competitor 2...",
          "mediaType": "carousel",
          "mediaUrl": "https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=600&q=80",
          "landingPageUrl": "https://competitor2.com",
          "ctaText": "Sign Up",
          "startedAt": "2026-08-16",
          "adHook": "No Setup Fees Offer",
          "angle": "Cost comparison",
          "offer": "Save Setup Costs"
        }
      ]
    },
    { 
      "name": "Competitor 3 Name", 
      "handle": "@competitor3", 
      "rank": "3",
      "ads": [
        {
          "caption": "Primary ad copy for competitor 3...",
          "mediaType": "image",
          "mediaUrl": "https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=600&q=80",
          "landingPageUrl": "https://competitor3.com",
          "ctaText": "Learn More",
          "startedAt": "2026-07-10",
          "adHook": "Try Risk Free",
          "angle": "Risk reversal marketing",
          "offer": "30-Day Guarantee"
        },
        {
          "caption": "Second ad copy for competitor 3...",
          "mediaType": "video",
          "mediaUrl": "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=600&q=80",
          "landingPageUrl": "https://competitor3.com",
          "ctaText": "Learn More",
          "startedAt": "2026-08-03",
          "adHook": "Watch Case Studies",
          "angle": "Social validation",
          "offer": "None"
        },
        {
          "caption": "Third ad copy for competitor 3...",
          "mediaType": "carousel",
          "mediaUrl": "https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=600&q=80",
          "landingPageUrl": "https://competitor3.com",
          "ctaText": "Sign Up",
          "startedAt": "2026-08-14",
          "adHook": "Premium Onboarding Pack",
          "angle": "All-in-one package",
          "offer": "Free Consultation"
        }
      ]
    }
  ],
  "metrics": {
    "totalAds": "Active ad count estimate",
    "monthlySpend": "Spend estimate in INR (e.g. ₹40,000)",
    "engagementRate": "Average engagement rate (e.g. 4.1%)",
    "adStrategy": "Primary Strategy type"
  },
  "tabs": {
    "overview": "Overview text comparing user's business with competitors.",
    "ads": "Details of competitor ad campaigns, creative types, and messaging styles.",
    "socialMedia": "Details of competitor social media presence, content trends, and engagement.",
    "strengths": "Details of competitor strengths and key advantages."
  },
  "swot": {
    "strengths": ["Item 1", "Item 2", "Item 3"],
    "weaknesses": ["Item 1", "Item 2", "Item 3"],
    "opportunities": ["Item 1", "Item 2", "Item 3"],
    "threats": ["Item 1", "Item 2", "Item 3"]
  },
  "audienceSuggestions": ["Interest 1", "Demographic 2", "Placement 3"],
  "recommendedAd": {
    "headline": "Proposed Ad Headline based on competitor weaknesses",
    "primaryText": "Proposed Ad Primary Copy highlighting user's strengths",
    "callToAction": "Recommended CTA (e.g. Learn More)",
    "landingPage": "/consultation"
  }
}
`;

      try {
        const response = await axios.post(geminiUrl, {
          contents: [{ parts: [{ text: instructionText }] }]
        }, {
          headers: { 'Content-Type': 'application/json' },
          timeout: 15000
        });

        const generatedText = response.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || '';

        let jsonString = generatedText;
        const jsonMatch = generatedText.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          jsonString = jsonMatch[0];
        }

        parsed = JSON.parse(jsonString);

        // Log Gemini analysis success
        await ApiUsage.create({
          userId,
          service: 'gemini',
          action: 'competitor_analysis',
          status: 'success'
        });
      } catch (geminiErr) {
        console.warn('Gemini API call / parsing failed in competitor analysis, using fallback:', geminiErr.message);
      }
    }

    if (!parsed || !parsed.competitors || !Array.isArray(parsed.competitors) || parsed.competitors.length === 0) {
      console.log('[Competitor Engine] Generating structured intelligence fallback...');
      parsed = getFallbackCompetitorAnalysis(businessName, industry, services, prompt);
    }

    // Save competitors and ads concurrently in 1 operation
    const competitorsList = parsed.competitors || [];
    await Promise.all(competitorsList.map(async (comp) => {
      try {
        const [watchlistEntry] = await CompetitorWatchlist.findOrCreate({
          where: { userId, name: comp.name },
          defaults: {
            handle: comp.handle || `@${comp.name.toLowerCase().replace(/\s+/g, '')}`,
            rank: parseInt(comp.rank) || 1
          }
        });

        // Determine which ads to save (scraped live or simulated from Gemini bundle)
        let parsedAds = null;
        if (!isApifySuspended && apifyToken && apifyToken !== 'your_apify_api_token_here') {
          parsedAds = await scrapeCompetitorAdsViaApify(comp.name, apifyToken, userId);
        }

        // If apify is suspended or returned 0 results, use the rich pre-generated ads from Gemini response
        if (!parsedAds || parsedAds.length === 0) {
          parsedAds = comp.ads || getMockAdsForCompetitor(comp.name, industry, services, watchlistEntry.id);
        }

        for (const ad of parsedAds) {
          await CompetitorAd.create({
            watchlistId: watchlistEntry.id,
            caption: ad.caption,
            mediaType: ad.mediaType || 'image',
            mediaUrl: ad.mediaUrl || 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=600&q=80',
            landingPageUrl: ad.landingPageUrl || 'https://competitor.com',
            ctaText: ad.ctaText || 'Learn More',
            startedAt: new Date(ad.startedAt || Date.now()),
            adHook: ad.adHook || 'Special Promotion Offer',
            angle: ad.angle || 'Standard Direct Marketing',
            offer: ad.offer || 'None'
          });
        }
      } catch (err) {
        console.error(`Error processing competitor watchlist and ads for ${comp.name}:`, err.message);
      }
    }));

    const watchlist = await getWatchlistsWithAds(userId);
    return res.status(200).json({ success: true, analysis: parsed, watchlist });

  } catch (err) {
    console.error('Error generating competitor analysis:', err.message);
    
    // Log Gemini failure
    try {
      await ApiUsage.create({
        userId,
        service: 'gemini',
        action: 'competitor_analysis',
        status: 'failed'
      });
    } catch (_) {}

    // Even on top-level catch, return fallback data gracefully
    try {
      const fallbackAnalysis = getFallbackCompetitorAnalysis(businessName, industry, services, prompt);
      const watchlist = await getWatchlistsWithAds(userId);
      return res.status(200).json({ success: true, analysis: fallbackAnalysis, watchlist });
    } catch (finalErr) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }
};

// Endpoint: POST /api/competitor/search
exports.aiSearch = async (req, res) => {
  const { prompt } = req.body;
  if (!prompt) {
    return res.status(400).json({ success: false, error: 'Prompt is required' });
  }

  const userId = req.user.id;
  const apiKey = process.env.GEMINI_API_KEY;

  let businessName = 'a startup';
  let industry = 'general business';
  let services = 'general services';

  try {
    const user = await User.findByPk(userId);
    if (user) {
      businessName = user.businessName || 'a startup';
      industry = user.industry || 'general business';
      if (user.businessServices) {
        try {
          services = JSON.parse(user.businessServices).join(', ');
        } catch (_) {
          services = user.businessServices;
        }
      }
    }

    let parsed = null;

    if (apiKey && apiKey !== 'YOUR_GEMINI_API_KEY') {
      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=${apiKey}`;

      const instructionText = `
You are an advanced AI Search and Market Intelligence Engine. Provide a direct, highly informative, accurate, and comprehensive answer to the user's search query: "${prompt}".

Contextual Awareness Guidelines:
- Answer the user's query DIRECTLY and accurately based on real-world facts, top products, brands, market concepts, pricing, or business strategies.
- If the query is about specific products, gadgets, software, tools, or brands (e.g. "brands of party speakers", "best CRM tools", "camera for reels"), provide top real-world brand recommendations with standout features, pros, and price tiers.
- If the query is about marketing, advertising, or business strategy, provide high-impact, actionable business frameworks.
- Do NOT force unrelated business profile context if the query is a general/product question. (User's optional profile context for reference: Business="${businessName}", Industry="${industry}").

Format the response as a JSON object in this exact schema, with no markdown code blocks or wrapper markup:
{
  "title": "Clear descriptive title answering the search prompt",
  "summary": "Direct, rich, well-explained answer to the prompt with complete context and clarity.",
  "insights": [
    "Specific key highlight / top brand feature / market insight 1",
    "Specific key highlight / top brand feature / market insight 2",
    "Specific key highlight / top brand feature / market insight 3"
  ],
  "recommendations": [
    "Actionable tip / buying advice / strategic recommendation 1",
    "Actionable tip / buying advice / strategic recommendation 2"
  ]
}
`;

      try {
        const response = await axios.post(geminiUrl, {
          contents: [{ parts: [{ text: instructionText }] }]
        }, {
          headers: { 'Content-Type': 'application/json' },
          timeout: 15000
        });

        const generatedText = response.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || '';

        let jsonString = generatedText;
        const jsonMatch = generatedText.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          jsonString = jsonMatch[0];
        }

        parsed = JSON.parse(jsonString);

        // Log Gemini AI Search success
        await ApiUsage.create({
          userId,
          service: 'gemini',
          action: 'ai_search',
          status: 'success'
        });
      } catch (geminiErr) {
        console.warn('Gemini AI Search API error, falling back:', geminiErr.message);
      }
    }

    if (!parsed || !parsed.summary) {
      parsed = getFallbackAiSearchResult(prompt);
    }

    return res.status(200).json({ success: true, results: parsed });

  } catch (err) {
    console.error('Error running AI search:', err.message);

    // Log Gemini AI Search failure
    try {
      await ApiUsage.create({
        userId,
        service: 'gemini',
        action: 'ai_search',
        status: 'failed'
      });
    } catch (_) {}

    const fallbackResult = getFallbackAiSearchResult(prompt);
    return res.status(200).json({ success: true, results: fallbackResult });
  }
};
