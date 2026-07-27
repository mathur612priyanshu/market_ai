const axios = require('axios');
const fs = require('fs');
const path = require('path');
const SocialAccount = require('../models/SocialAccount');
const ScheduledPost = require('../models/ScheduledPost');

// Endpoint: POST /api/posts/generate
// Generates captions/hashtags using Google Gemini 1.5 Flash
exports.generatePostContent = async (req, res) => {
  const { prompt, platform, tone, type } = req.body;

  if (!prompt) {
    return res.status(400).json({ success: false, error: 'Prompt is required' });
  }

  // Promise to generate image via Pollinations.ai and save locally
  const imagePromise = (async () => {
    try {
      const encodedPrompt = encodeURIComponent(prompt + ", social media marketing banner, professional advertising graphic design");
      const seed = Math.floor(Math.random() * 1000000);
      const pollinationsUrl = `https://image.pollinations.ai/prompt/${encodedPrompt}?width=600&height=600&nologo=true&seed=${seed}`;

      const imgResponse = await axios.get(pollinationsUrl, { responseType: 'arraybuffer', timeout: 10000 });
      
      const fileName = `creative_${Date.now()}.jpg`;
      const uploadsDir = path.join(__dirname, '../uploads');
      const uploadPath = path.join(uploadsDir, fileName);
      
      // Ensure uploads folder exists
      if (!fs.existsSync(uploadsDir)) {
        fs.mkdirSync(uploadsDir, { recursive: true });
      }
      
      fs.writeFileSync(uploadPath, Buffer.from(imgResponse.data));
      return `${req.protocol}://${req.get('host')}/uploads/${fileName}`;
    } catch (imgError) {
      console.error('Error generating image from Pollinations:', imgError.message);
      // Fallback high-quality stock image
      return 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=600&auto=format&fit=crop&q=60';
    }
  })();

  const apiKey = process.env.GEMINI_API_KEY;

  // Fallback mock responses if API Key is not set or fails
  const getFallbackResponse = async () => {
    const defaultHashtags = `#${platform}Marketing #${tone}Tone #MarketAI #${type.replace(/\s+/g, '')}`;
    const creativeUrl = await imagePromise;
    return {
      caption: `🚀 Boost your business presence with dynamic marketing! We are focusing on "${prompt}" customized for our audience. Let's make an impact today!`,
      hashtags: defaultHashtags,
      creativeUrl
    };
  };

  if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY') {
    console.warn('Gemini API Key is not configured. Serving high-quality fallback post.');
    const fallbackRes = await getFallbackResponse();
    return res.status(200).json({ success: true, ...fallbackRes });
  }

  try {
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=${apiKey}`;
    
    const instructionText = `Write a social media post for ${platform} about: "${prompt}". The tone should be ${tone}. The post type is ${type}. Return ONLY a JSON object in this exact format, with no markdown styling or markdown code block wrapper: { "caption": "caption content here", "hashtags": "#hashtag1 #hashtag2" }`;

    // Concurrently fetch from Gemini and Pollinations image downloader
    const [geminiRes, generatedImageUrl] = await Promise.all([
      axios.post(geminiUrl, {
        contents: [{ parts: [{ text: instructionText }] }]
      }, { headers: { 'Content-Type': 'application/json' } }),
      imagePromise
    ]);

    const generatedText = geminiRes.data.candidates[0].content.parts[0].text.trim();
    
    // Clean markdown wrappers if present (e.g. ```json ... ```)
    let jsonString = generatedText;
    if (jsonString.startsWith('```')) {
      jsonString = jsonString.replace(/^```json\s*/i, '').replace(/```$/, '').trim();
    }

    try {
      const parsedData = JSON.parse(jsonString);
      return res.status(200).json({
        success: true,
        caption: parsedData.caption || parsedData.text || '',
        hashtags: parsedData.hashtags || '',
        creativeUrl: generatedImageUrl
      });
    } catch (parseError) {
      console.warn('Failed to parse Gemini JSON output. Raw output was:', generatedText);
      // Regex fallback if JSON parsing failed
      return res.status(200).json({
        success: true,
        caption: generatedText.substring(0, 150) + '...',
        hashtags: `#${platform} #Marketing`,
        creativeUrl: generatedImageUrl
      });
    }

  } catch (error) {
    console.error('Error generating post with Gemini:', error.message);
    const fallbackRes = await getFallbackResponse();
    return res.status(200).json({ success: true, ...fallbackRes });
  }
};

// Endpoint: POST /api/posts/schedule
// Schedules a post in the database or publishes it immediately using Meta Graph APIs
exports.publishOrSchedulePost = async (req, res) => {
  const userId = req.user.id;
  const { platform, caption, hashtags, mediaUrl, scheduledTime } = req.body;

  if (!platform || !caption) {
    return res.status(400).json({ success: false, error: 'Platform and caption are required' });
  }

  const isFacebook = platform.toLowerCase() === 'facebook';
  const targetPlatform = isFacebook ? 'facebook' : 'instagram';

  try {
    // 1. If scheduled for a future time
    if (scheduledTime) {
      const scheduleDate = new Date(scheduledTime);
      const now = new Date();

      if (scheduleDate > now) {
        const post = await ScheduledPost.create({
          userId,
          platform: targetPlatform,
          caption,
          hashtags,
          mediaUrl,
          scheduledTime: scheduleDate,
          status: 'pending'
        });

        return res.status(200).json({
          success: true,
          message: 'Post scheduled successfully!',
          post
        });
      }
    }

    // 2. Publish Immediately (Publish Now)
    const account = await SocialAccount.findOne({
      where: { userId, platform: targetPlatform }
    });

    if (!account) {
      return res.status(400).json({
        success: false,
        error: `No connected ${targetPlatform === 'facebook' ? 'Facebook Page' : 'Instagram Account'} found for this user. Please connect it first.`
      });
    }

    const fullText = hashtags ? `${caption}\n\n${hashtags}` : caption;

    // 3. Call Meta Graph API
    if (isFacebook) {
      if (mediaUrl) {
        // Publish Photo Post
        await axios.post(`https://graph.facebook.com/v20.0/${account.accountId}/photos`, null, {
          params: {
            url: mediaUrl,
            message: fullText,
            access_token: account.accessToken
          }
        });
      } else {
        // Publish Text/Feed Post
        await axios.post(`https://graph.facebook.com/v20.0/${account.accountId}/feed`, null, {
          params: {
            message: fullText,
            access_token: account.accessToken
          }
        });
      }
    } else {
      // Instagram Container Publishing (2 Steps)
      // Step A: Create media item container
      const containerRes = await axios.post(`https://graph.facebook.com/v20.0/${account.accountId}/media`, null, {
        params: {
          image_url: mediaUrl || 'https://images.unsplash.com/photo-1611162617213-7d7a39e9b1d7?w=600', // Default placeholder if none
          caption: fullText,
          access_token: account.accessToken
        }
      });

      const containerId = containerRes.data.id;

      // Step B: Publish the container
      await axios.post(`https://graph.facebook.com/v20.0/${account.accountId}/media_publish`, null, {
        params: {
          creation_id: containerId,
          access_token: account.accessToken
        }
      });
    }

    // Save history in database as published
    const post = await ScheduledPost.create({
      userId,
      platform: targetPlatform,
      caption,
      hashtags,
      mediaUrl,
      scheduledTime: new Date(),
      status: 'published'
    });

    return res.status(200).json({
      success: true,
      message: 'Post published successfully to Meta social feed!',
      post
    });

  } catch (error) {
    const errorDetails = error.response ? JSON.stringify(error.response.data) : error.message;
    console.error('Error publishing post to Meta:', errorDetails);

    // Save history in database as failed
    await ScheduledPost.create({
      userId,
      platform: targetPlatform,
      caption,
      hashtags,
      mediaUrl,
      scheduledTime: new Date(),
      status: 'failed',
      errorMessage: errorDetails
    });

    return res.status(500).json({
      success: false,
      error: 'Failed to publish post directly to Meta. Make sure the linked pages/instagram profiles are active, permissions are granted, and you are using real tokens.'
    });
  }
};
