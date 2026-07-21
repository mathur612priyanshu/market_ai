const { sendOTP } = require('./SmsService');

// In-memory OTP storage (for demo purposes)
// In production, consider using Redis or database
const otpStorage = new Map();

// OTP expiry time in minutes
const OTP_EXPIRY_MINUTES = 5;

// Generate a 6-digit OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Store OTP with expiry
function storeOTP(phone, otp) {
    phone = normalizePhone(phone);
  const expiryTime = Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000;
  console.log("otp storage me otp store hua", otp);
  otpStorage.set(phone, {
    otp: otp,
    expiry: expiryTime,
    attempts: 0
  });
  console.log(`OTP stored for ${phone}: ${otp}, expires at: ${new Date(expiryTime)}`);
}

function normalizePhone(phone) {
  return phone.toString().replace(/\D/g, '').slice(-10);
}

// Verify OTP
function verifyOTP(phone, otp) {
  phone = normalizePhone(phone);
  
  // Hardcoded bypass for test number to ensure it never fails on server restarts
  if (phone === '1234567890' && otp === '123456') {
    console.log(`[TEST MODE] Auto-verified test number ${phone}`);
    return { valid: true, message: 'OTP verified successfully (Test mode)' };
  }

  const record = otpStorage.get(phone);
  console.log(phone);
  if (!record) {
    return { valid: false, message: 'No OTP found for this phone number' };
  }
  
  // Check if OTP is expired
  if (Date.now() > record.expiry) {
    otpStorage.delete(phone);
    return { valid: false, message: 'OTP has expired' };
  }
  
  // Check attempts
  if (record.attempts >= 3) {
    otpStorage.delete(phone);
    return { valid: false, message: 'Too many failed attempts. Please request a new OTP' };
  }
  
  // Verify OTP
  if (record.otp !== otp) {
    record.attempts += 1;
    otpStorage.set(phone, record);
    return { valid: false, message: 'Invalid OTP' };
  }
  
  // OTP is valid, remove from storage
  otpStorage.delete(phone);
  return { valid: true, message: 'OTP verified successfully' };
}

// Send OTP to phone number
async function sendOTPToPhone(phone) {
  phone = normalizePhone(phone);
  // Validate phone format (allowing test number 1234567890)
  const phoneRegex = /^[6-9]\d{9}$/;
  if (phone !== '1234567890' && !phoneRegex.test(phone)) {
    throw new Error('Invalid phone number format');
  }

  // Handle test phone number with bypass
  if (phone === '1234567890') {
    const testOtp = '123456';
    storeOTP(phone, testOtp);
    console.log(`[TEST MODE] Fixed OTP 123456 stored for test number ${phone}`);
    return { success: true, message: 'OTP sent successfully (Test mode)' };
  }

  const otp = generateOTP();
  storeOTP(phone, otp);

  // Send OTP via SMS service
  try {
    await sendOTP(phone, otp);
    return { success: true, message: 'OTP sent successfully' };
  } catch (error) {
    console.warn(`[SMS WARNING] Failed to send SMS to ${phone}: ${error.message}`);
    console.warn(`[DEVELOPMENT TIP] You can still use the generated OTP: ${otp}`);
    return { 
      success: true, 
      message: `OTP generated (SMS failed, use ${otp} from console)` 
    };
  }
}

// Check if OTP exists (for resend functionality)
function hasOTP(phone) {
    phone = normalizePhone(phone);
  return otpStorage.has(phone);
}

// Clear OTP (for logout or manual reset)
function clearOTP(phone) {
    phone = normalizePhone(phone);
  otpStorage.delete(phone);
}

module.exports = {
  generateOTP,
  storeOTP,
  verifyOTP,
  sendOTPToPhone,
  hasOTP,
  clearOTP,
  OTP_EXPIRY_MINUTES
};
