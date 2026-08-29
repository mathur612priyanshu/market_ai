const axios = require('axios');
const fs = require('fs');
const path = require('path');
const SocialAccount = require('../models/SocialAccount');
const ScheduledPost = require('../models/ScheduledPost');
const ApiUsage = require('../models/ApiUsage');

// Endpoint: POST /api/posts/generate
// Generates captions/hashtags using Google Gemini 1.5 Flash
// Endpoint: POST /api/posts/generate
// Generates captions/hashtags using Google Gemini 3.6 Flash
exports.generatePostContent = async (req, res) => {
  const { prompt, platform, tone, type } = req.body;

  if (!prompt) {
    return res.status(400).json({ success: false, error: 'Prompt is required' });
  }

  const apiKey = process.env.GEMINI_API_KEY;

  // Helper to generate image via Pollinations.ai and save locally
  const generatePollinationsImage = async (imagePrompt) => {
    try {
      const finalPrompt = `${imagePrompt}, ultra-realistic, cinematic lighting, 8k resolution, highly detailed, photorealistic, professional commercial photography, studio lighting, no text, no logo`;
      const encodedPrompt = encodeURIComponent(finalPrompt);
      const seed = Math.floor(Math.random() * 1000000);
      const pollinationsUrl = `https://image.pollinations.ai/prompt/${encodedPrompt}?width=600&height=600&nologo=true&seed=${seed}`;

      const imgResponse = await axios.get(pollinationsUrl, { responseType: 'arraybuffer', timeout: 15000 });
      
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
  };

  // Fallback response generator if Gemini fails or is not configured
  const getFallbackResponse = async () => {
    const defaultHashtags = `#${platform}Marketing #${tone}Tone #MarketAI #${type.replace(/\s+/g, '')}`;
    const creativeUrl = await generatePollinationsImage(prompt);
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
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=${apiKey}`;
    
    const instructionText = `
You are a creative social media manager. Write a social media post for ${platform} about: "${prompt}".
The tone of the caption should be ${tone}.
The post type is ${type}.

Also, provide details for finding or generating an image for this post:
1. "imagePrompt": A highly descriptive, text-free, ultra-realistic image generation scene prompt (professional commercial photography style, no text, letters, or logos).
2. "searchKeywords": A simple 2-3 word search query (keywords) suitable for searching realistic commercial stock photos on Unsplash (e.g., "chocolate pastry", "office brainstorming", "running shoes").

Return ONLY a JSON object in this exact format, with no markdown styling or markdown code block wrapper:
{
  "caption": "caption content here",
  "hashtags": "#hashtag1 #hashtag2",
  "imagePrompt": "A detailed descriptive scene prompt for generating a high-quality realistic image without any text overlays",
  "searchKeywords": "2-3 simple keywords for stock photo search"
}
`;

    const geminiRes = await axios.post(geminiUrl, {
      contents: [{ parts: [{ text: instructionText }] }]
    }, { headers: { 'Content-Type': 'application/json' } });

    const generatedText = geminiRes.data.candidates[0].content.parts[0].text.trim();
    
    // Clean markdown wrappers if present (e.g. ```json ... ```)
    let jsonString = generatedText;
    if (jsonString.startsWith('```')) {
      jsonString = jsonString.replace(/^```json\s*/i, '').replace(/```$/, '').trim();
    }

    let parsedData = {};
    let imagePrompt = prompt;
    let searchKeywords = '';

    try {
      parsedData = JSON.parse(jsonString);
      if (parsedData.imagePrompt) {
        imagePrompt = parsedData.imagePrompt;
      }
      if (parsedData.searchKeywords) {
        searchKeywords = parsedData.searchKeywords;
      }
    } catch (parseError) {
      console.warn('Failed to parse Gemini JSON output. Raw output was:', generatedText);
      parsedData = {
        caption: generatedText.substring(0, 150) + '...',
        hashtags: `#${platform} #Marketing`
      };
    }

    let generatedImageUrl = null;

    // 1. Try fetching from Unsplash if key and searchKeywords are available
    if (process.env.UNSPLASH_ACCESS_KEY && searchKeywords) {
      try {
        console.log(`[Image Finder] Attempting Unsplash search for: "${searchKeywords}"`);
        const unsplashRes = await axios.get('https://api.unsplash.com/search/photos', {
          params: {
            query: searchKeywords,
            per_page: 1,
            client_id: process.env.UNSPLASH_ACCESS_KEY
          },
          timeout: 5000
        });
        if (unsplashRes.data && unsplashRes.data.results && unsplashRes.data.results.length > 0) {
          generatedImageUrl = unsplashRes.data.results[0].urls.regular;
          console.log('[Image Finder] Found Unsplash stock image:', generatedImageUrl);
        } else {
          console.log('[Image Finder] No results found on Unsplash. Falling back to AI generator.');
        }
      } catch (unsplashErr) {
        console.warn('[Image Finder] Unsplash API search failed. Falling back to AI generator. Error:', unsplashErr.message);
      }
    }

    // 2. Fallback to Pollinations AI generator if Unsplash was not used or failed
    if (!generatedImageUrl) {
      generatedImageUrl = await generatePollinationsImage(imagePrompt);
    }

    // Log dynamic API Usage for post generation
    await ApiUsage.create({
      userId: req.user.id,
      service: 'gemini',
      action: 'post_generation',
      status: 'success'
    });

    return res.status(200).json({
      success: true,
      caption: parsedData.caption || parsedData.text || '',
      hashtags: parsedData.hashtags || '',
      creativeUrl: generatedImageUrl
    });

  } catch (error) {
    console.error('Error generating post with Gemini:', error.message);
    
    // Log failed post generation attempt
    await ApiUsage.create({
      userId: req.user.id,
      service: 'gemini',
      action: 'post_generation',
      status: 'failed'
    });

    const fallbackRes = await getFallbackResponse();
    return res.status(200).json({ success: true, ...fallbackRes });
  }
};

// Endpoint: POST /api/posts/schedule
// Schedules a post in the database or publishes it immediately using Meta Graph APIs
exports.publishOrSchedulePost = async (req, res) => {
  const userId = req.user.id;
  const { platform, caption, hashtags, mediaUrl, scheduledTime, prompt, tone, type } = req.body;

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
          status: 'pending',
          prompt,
          tone,
          type
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
    // 3. Call Meta Graph API
    if (isFacebook) {
      if (mediaUrl) {
        const isVideo = mediaUrl.toLowerCase().match(/\.(mp4|mov|avi|mkv|3gp|webm)$/) || mediaUrl.includes('video');
        if (isVideo) {
          // Publish Video/Reel Post
          await axios.post(`https://graph.facebook.com/v20.0/${account.accountId}/videos`, null, {
            params: {
              file_url: mediaUrl,
              description: fullText,
              access_token: account.accessToken
            }
          });
        } else {
          // Publish Photo Post
          await axios.post(`https://graph.facebook.com/v20.0/${account.accountId}/photos`, null, {
            params: {
              url: mediaUrl,
              message: fullText,
              access_token: account.accessToken
            }
          });
        }
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
      const isVideo = mediaUrl && (mediaUrl.toLowerCase().match(/\.(mp4|mov|avi|mkv|3gp|webm)$/) || mediaUrl.includes('video'));
      
      // Step A: Create media item container
      const containerRes = await axios.post(`https://graph.facebook.com/v20.0/${account.accountId}/media`, null, {
        params: isVideo ? {
          media_type: 'REELS',
          video_url: mediaUrl,
          caption: fullText,
          access_token: account.accessToken
        } : {
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
      status: 'published',
      prompt,
      tone,
      type
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
      errorMessage: errorDetails,
      prompt,
      tone,
      type
    });



    return res.status(500).json({
      success: false,
      error: 'Failed to publish post directly to Meta. Make sure the linked pages/instagram profiles are active, permissions are granted, and you are using real tokens.'
    });
  }
};
