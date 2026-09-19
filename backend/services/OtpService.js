const { sendOTP, normalizePhone } = require('./SmsService');

// In-memory OTP storage
const otpStorage = new Map();

// OTP expiry time in minutes
const OTP_EXPIRY_MINUTES = 10;

// Generate a 6-digit OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Store OTP with expiry
function storeOTP(phone, otp) {
  const normalized = normalizePhone(phone);
  const expiryTime = Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000;
  
  otpStorage.set(normalized, {
    otp: otp,
    expiry: expiryTime,
    attempts: 0
  });

  console.log('\n======================================================');
  console.log('📱 [OTP AUTHENTICATION]');
  console.log(`📞 Phone Number : +91 ${normalized}`);
  console.log(`🔑 OTP Code     : ${otp}`);
  console.log(`⏰ Expires At   : ${new Date(expiryTime).toLocaleTimeString()}`);
  console.log('======================================================\n');
}

// Verify OTP
function verifyOTP(phone, otp) {
  const normalized = normalizePhone(phone);
  
  // Test numbers bypass
  const testPhones = ['1234567890', '9999999999', '0000000000', '9876543210', '8888888888'];
  if (testPhones.includes(normalized) && (otp === '123456' || otp === '000000')) {
    console.log(`[TEST MODE] Auto-verified test number ${normalized} with fixed OTP ${otp}`);
    return { valid: true, message: 'OTP verified successfully (Test mode)' };
  }

  // Developer master OTP for local testing
  if (process.env.NODE_ENV !== 'production' && otp === '123456') {
    console.log(`[DEV MASTER OTP] Auto-verified ${normalized} with developer code 123456`);
    return { valid: true, message: 'OTP verified successfully (Dev master key)' };
  }

  const record = otpStorage.get(normalized);
  if (!record) {
    return { valid: false, message: 'No OTP found or OTP expired for this phone number' };
  }
  
  // Check if OTP is expired
  if (Date.now() > record.expiry) {
    otpStorage.delete(normalized);
    return { valid: false, message: 'OTP has expired. Please request a new one.' };
  }
  
  // Check attempts
  if (record.attempts >= 5) {
    otpStorage.delete(normalized);
    return { valid: false, message: 'Too many failed attempts. Please request a new OTP.' };
  }
  
  // Verify OTP
  if (record.otp !== otp) {
    record.attempts += 1;
    otpStorage.set(normalized, record);
    return { valid: false, message: 'Invalid OTP' };
  }
  
  // OTP is valid, remove from storage
  otpStorage.delete(normalized);
  return { valid: true, message: 'OTP verified successfully' };
}

// Send OTP to phone number
async function sendOTPToPhone(phone) {
  const normalized = normalizePhone(phone);
  
  if (normalized.length !== 10) {
    throw new Error('Invalid phone number. Must be a 10-digit number.');
  }

  // Handle test phone number with bypass
  if (normalized === '1234567890') {
    const testOtp = '123456';
    storeOTP(normalized, testOtp);
    return { success: true, message: 'OTP sent successfully (Test mode)', otp: testOtp };
  }

  const otp = generateOTP();
  storeOTP(normalized, otp);

  // Send OTP via SMS service (2Factor API)
  try {
    await sendOTP(normalized, otp);
    return { success: true, message: 'OTP sent successfully', otp };
  } catch (error) {
    console.warn(`[SMS NOTICE] Live SMS gateway delivery failed: ${error.message}`);
    console.log(`[DEVELOPMENT TIP] Use the generated OTP displayed above in console: ${otp}`);
    return { 
      success: true, 
      message: `OTP generated! Check server console for code: ${otp}`,
      otp 
    };
  }
}

// Check if OTP exists (for resend functionality)
function hasOTP(phone) {
  const normalized = normalizePhone(phone);
  return otpStorage.has(normalized);
}

// Clear OTP (for logout or manual reset)
function clearOTP(phone) {
  const normalized = normalizePhone(phone);
  otpStorage.delete(normalized);
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

