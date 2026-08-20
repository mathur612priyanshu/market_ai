const axios = require('axios');
const User = require('../models/User');
const CompetitorWatchlist = require('../models/CompetitorWatchlist');
const CompetitorAd = require('../models/CompetitorAd');

let isApifySuspended = false;

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

async function scrapeCompetitorAdsViaApify(competitorName, apifyToken) {
  if (isApifySuspended) {
    return null;
  }

  try {
    console.log(`[Apify Crawler] Scraping Meta Ad Library for: ${competitorName}`);
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
      return response.data.map(item => {
        const adCopy = item.adCopy || item.text || item.caption || '';
        let mediaType = 'image';
        if (item.mediaType) {
          mediaType = item.mediaType.toLowerCase();
        } else if (item.videoUrl) {
          mediaType = 'video';
        } else if (item.carouselItems && item.carouselItems.length > 0) {
          mediaType = 'carousel';
        }

        return {
          caption: adCopy,
          mediaType: mediaType,
          mediaUrl: item.mediaUrl || item.imageUrl || item.videoUrl || 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=600&q=80',
          landingPageUrl: item.landingPage || item.landingPageUrl || 'https://www.facebook.com/ads/library',
          ctaText: item.ctaText || item.ctaType || 'Learn More',
          startedAt: item.startDate || item.startedAt || new Date().toISOString()
        };
      });
    }
  } catch (err) {
    console.warn(`[Apify Crawler] Scraper run failed for ${competitorName}:`, err.message);
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
  const { prompt } = req.body;
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

    if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY') {
      return res.status(400).json({ success: false, error: 'Gemini API Key is not configured on the server. Please add GEMINI_API_KEY to your .env file.' });
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

    const response = await axios.post(geminiUrl, {
      contents: [{ parts: [{ text: instructionText }] }]
    }, { headers: { 'Content-Type': 'application/json' } });

    const generatedText = response.data.candidates[0].content.parts[0].text.trim();

    let jsonString = generatedText;
    if (jsonString.startsWith('```')) {
      jsonString = jsonString.replace(/^```json\s*/i, '').replace(/```$/, '').trim();
    }

    parsed = JSON.parse(jsonString);

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
        if (apifyToken && apifyToken !== 'your_apify_token_here') {
          parsedAds = await scrapeCompetitorAdsViaApify(comp.name, apifyToken);
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
    return res.status(500).json({ success: false, error: err.message });
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

    if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY') {
      return res.status(400).json({ success: false, error: 'Gemini API Key is not configured on the server. Please add GEMINI_API_KEY to your .env file.' });
    }

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=${apiKey}`;

    const instructionText = `
You are a brilliant AI marketing strategist. Answer this search query: "${prompt}".
Tailor the answer specifically to this business context:
- Business Name: "${businessName}"
- Industry/Niche: "${industry}"
- Key Services Offered: "${services}"

Format the response as a JSON object in this exact schema, with no markdown code blocks or wrapper markup:
{
  "summary": "Clear, detailed response answering the search prompt.",
  "insights": [
    "Insight 1 explaining target market or competitor behavior",
    "Insight 2 explaining user query details"
  ],
  "recommendations": [
    "Actionable step 1 for the user to execute",
    "Actionable step 2 for the user to execute"
  ]
}
`;

    const response = await axios.post(geminiUrl, {
      contents: [{ parts: [{ text: instructionText }] }]
    }, { headers: { 'Content-Type': 'application/json' } });

    const generatedText = response.data.candidates[0].content.parts[0].text.trim();

    let jsonString = generatedText;
    if (jsonString.startsWith('```')) {
      jsonString = jsonString.replace(/^```json\s*/i, '').replace(/```$/, '').trim();
    }

    const parsed = JSON.parse(jsonString);
    return res.status(200).json({ success: true, results: parsed });

  } catch (err) {
    console.error('Error running AI search:', err.message);
    return res.status(500).json({ success: false, error: err.message });
  }
};
