const axios = require('axios');

function normalizePhone(phone) {
  return phone ? phone.toString().replace(/\D/g, '').slice(-10) : '';
}

function validatePhone(phone) {
  const normalized = normalizePhone(phone);
  return normalized.length === 10;
}

async function sendOTP(phone, otp) {
  const normalized = normalizePhone(phone);
  const apiKey = process.env.TWOFACTOR_API_KEY;

  if (!apiKey || apiKey === 'YOUR_TWOFACTOR_API_KEY') {
    console.warn(`[2Factor SMS] TWOFACTOR_API_KEY is not configured. Serving local OTP mode.`);
    return { Status: 'Success', Details: 'Local development mode' };
  }

  // Validate phone format before sending
  if (!validatePhone(normalized)) {
    throw new Error("Invalid phone number format. Must be 10 digits.");
  }

  const url = `https://2factor.in/API/V1/${apiKey}/SMS/${normalized}/${otp}/OTP1`;

  try {
    console.log(`[2Factor SMS] Sending live SMS OTP to +91 ${normalized}...`);
    const response = await axios.get(url, { timeout: 6000 });
    console.log('[2Factor SMS] API Response:', response.data);
    return response.data;
  } catch (error) {
    console.warn('[2Factor SMS] Failed to dispatch live SMS:', error.response?.data || error.message);
    throw new Error("Failed to send OTP via SMS gateway");
  }
}

module.exports = { sendOTP, normalizePhone, validatePhone };

