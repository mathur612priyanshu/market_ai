const axios = require('axios');

function validatePhone(phone) {
  // Simple Indian phone number validation (modify for your needs)
  // Starts with 6-9, total 10 digits
  const phoneRegex = /^[6-9]\d{9}$/;
  console.log(phone);
  return phoneRegex.test(phone);
}

async function sendOTP(phone, otp) {
  const apiKey = process.env.TWOFACTOR_API_KEY;

  if (!apiKey) {
    throw new Error("TWOFACTOR_API_KEY environment variable not set");
  }

  // Validate phone format before sending
  if (!validatePhone(phone)) {
    throw new Error("Invalid phone number format");
  }

  const url = `https://2factor.in/API/V1/${apiKey}/SMS/${phone}/${otp}/OTP1`;

  try {
    console.log(`Sending OTP to ${phone}`);
    const response = await axios.get(url);
    console.log('2Factor API response:', response.data);
    return response.data;
  } catch (error) {
    console.error("Error sending OTP via 2Factor");

    if (error.response) {
      console.error("Status:", error.response.status);
      console.error("Response Body:", error.response.data);
    } else {
      console.error("Error Message:", error.message);
    }

    throw new Error("Failed to send OTP");
  }
}

module.exports = { sendOTP };
