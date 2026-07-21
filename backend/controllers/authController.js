const jwt = require('jsonwebtoken');
const OtpService = require('../services/OtpService');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'market_ai_jwt_secret_key';

exports.sendOtp = async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      return res.status(400).json({ success: false, message: 'Phone number is required' });
    }

    const result = await OtpService.sendOTPToPhone(phone);
    return res.status(200).json({ success: true, message: result.message });
  } catch (error) {
    console.error('Error in sendOtp controller:', error.message);
    return res.status(500).json({ success: false, message: error.message || 'Internal Server Error' });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const { phone, otp } = req.body;
    if (!phone || !otp) {
      console.error('Phone or OTP not provided in request body');
      return res.status(400).json({ success: false, message: 'Phone and OTP are required' });
    }

    const result = OtpService.verifyOTP(phone, otp);
    if (!result.valid) {
      console.log(`OTP verification failed for phone: ${phone}, reason: ${result.message}`);
      return res.status(400).json({ success: false, message: result.message });
    }

    // Normalize phone
    const normalizedPhone = phone.toString().replace(/\D/g, '').slice(-10);

    // Find or create user in database
    const [user, created] = await User.findOrCreate({
      where: { phone: normalizedPhone }
    });

    // Generate JWT token
    const token = jwt.sign(
      { id: user.id, phone: user.phone },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log(`User logged in successfully: ${user.id}`);

    return res.status(200).json({
      success: true,
      message: 'OTP verified successfully',
      token,
      user,
      isNewUser: created
    });
  } catch (error) {
    console.error('Error in verifyOtp controller:', error.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { name, email, industry, country } = req.body;
    
    // req.user is set by authMiddleware
    if (!req.user || !req.user.id) {
      return res.status(401).json({ success: false, message: 'Unauthorized access' });
    }

    const user = await User.findByPk(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    await user.update({
      name: name !== undefined ? name : user.name,
      email: email !== undefined ? email : user.email,
      industry: industry !== undefined ? industry : user.industry,
      country: country !== undefined ? country : user.country
    });

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      user
    });
  } catch (error) {
    console.error('Error in updateProfile controller:', error.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.uploadAvatar = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }

    // req.user.id is set by authMiddleware
    const user = await User.findByPk(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Store relative file path URL
    const fileUrl = `/uploads/${req.file.filename}`;
    await user.update({ profilePicture: fileUrl });

    return res.status(200).json({
      success: true,
      message: 'Profile picture uploaded successfully',
      profilePicture: fileUrl,
      user
    });
  } catch (error) {
    console.error('Error in uploadAvatar controller:', error.message);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};
