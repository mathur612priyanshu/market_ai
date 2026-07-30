const axios = require('axios');
const User = require('../models/User');

exports.analyzeCompetitors = async (req, res) => {
  const { prompt } = req.body;
  if (!prompt) {
    return res.status(400).json({ success: false, error: 'Prompt is required' });
  }

  const userId = req.user.id;
  const apiKey = process.env.GEMINI_API_KEY;

  try {
    const user = await User.findByPk(userId);
    const businessName = user?.businessName || 'a startup';
    const industry = user?.industry || 'general business';
    let services = 'general services';
    if (user?.businessServices) {
      try {
        services = JSON.parse(user.businessServices).join(', ');
      } catch (_) {
        services = user.businessServices;
      }
    }

    // Fallback mock payload if API key is missing or fails
    const getFallbackPayload = () => ({
      competitors: [
        { name: 'DigiGrowth Solutions', handle: '@digigrowth', rank: '1' },
        { name: 'BrandBoost Agency', handle: '@brandboost', rank: '2' },
        { name: 'Clickify Media', handle: '@clickify', rank: '3' }
      ],
      metrics: {
        totalAds: '128',
        monthlySpend: '₹45,000',
        engagementRate: '3.8%',
        adStrategy: 'Lead Generation'
      },
      tabs: {
        overview: `Competitor overview for ${businessName}. Your top competitors in the ${industry} sector are actively deploying lead capturing forms.`,
        ads: 'Competitors are focusing on high-frequency Facebook Carousel Ads featuring promotional offers.',
        socialMedia: 'Competitors maintain an average posting frequency of 3-4 posts per week, focusing on reels and shorts.',
        strengths: 'Key advantages include strong local brand recall, fast response times on social media, and discounts.'
      },
      swot: {
        strengths: ['Agile operations', 'Personalized client care'],
        weaknesses: ['Limited advertising budget', 'New brand presence'],
        opportunities: ['Tap into Instagram Reels', 'Offer free consults'],
        threats: ['Established competitors', 'Higher ad bid rates']
      },
      audienceSuggestions: ['Business Owners', 'Young Professionals', 'Instagram Users'],
      recommendedAd: {
        headline: `Boost Your ${industry} Business Today`,
        primaryText: `We provide professional ${services} tailored for you. Get a free consultation now!`,
        callToAction: 'Book Now',
        landingPage: '/consultation'
      }
    });

    if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY') {
      console.warn('Gemini API Key not set. Serving fallback competitor analysis.');
      return res.status(200).json({ success: true, analysis: getFallbackPayload() });
    }

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${apiKey}`;

    const instructionText = `
You are a top-tier business marketing analyst. Analyze competitors for this business profile:
- Business Name: "${businessName}"
- Industry: "${industry}"
- Services Offered: "${services}"
- Search Prompt/Goal: "${prompt}"

Produce a detailed competitor analysis and marketing strategy. Return ONLY a JSON object in this exact schema, with no markdown code block formatting or styling wrapper:
{
  "competitors": [
    { "name": "Competitor 1 Name", "handle": "@competitor1", "rank": "1" },
    { "name": "Competitor 2 Name", "handle": "@competitor2", "rank": "2" },
    { "name": "Competitor 3 Name", "handle": "@competitor3", "rank": "3" }
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

    // Clean markdown code blocks if returned
    let jsonString = generatedText;
    if (jsonString.startsWith('```')) {
      jsonString = jsonString.replace(/^```json\s*/i, '').replace(/```$/, '').trim();
    }

    try {
      const parsed = JSON.parse(jsonString);
      return res.status(200).json({ success: true, analysis: parsed });
    } catch (parseError) {
      console.warn('Failed to parse Gemini Competitor JSON output. Raw was:', generatedText);
      return res.status(200).json({ success: true, analysis: getFallbackPayload() });
    }

  } catch (err) {
    console.error('Error generating competitor analysis:', err.message);
    return res.status(500).json({ success: false, error: 'Internal Server Error' });
  }
};
