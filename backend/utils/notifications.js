const nodemailer = require('nodemailer');
const { admin } = require('./firebase');
const User = require('../models/User');

// Email Transporter (Mock - requires actual SMTP credentials for production)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER || 'riyobox.app@gmail.com',
    pass: process.env.EMAIL_PASS || 'mock_password',
  },
});

const sendWelcomeEmail = async (email, name) => {
  try {
    const mailOptions = {
      from: '"RIYOBOX Team" <riyobox.app@gmail.com>',
      to: email,
      subject: 'Welcome to RIYOBOX!',
      text: `Hi ${name},\n\nThank you for joining RIYOBOX! We are excited to have you with us.\n\nEnjoy unlimited streaming!`,
      html: `<h1>Welcome to RIYOBOX!</h1><p>Hi ${name},</p><p>Thank you for joining RIYOBOX! We are excited to have you with us.</p><p>Enjoy unlimited streaming!</p>`,
    };

    if (process.env.NODE_ENV !== 'production' && !process.env.EMAIL_PASS) {
      console.log(`📧 [MOCK EMAIL] Welcome email to ${email}`);
      return;
    }

    await transporter.sendMail(mailOptions);
    console.log(`✅ Welcome email sent to ${email}`);
  } catch (error) {
    console.error('❌ Error sending welcome email:', error.message);
  }
};

const sendPushNotification = async (title, body, data = {}) => {
  try {
    if (admin.apps.length === 0) {
      console.log(`📱 [MOCK PUSH] ${title}: ${body}`);
      return;
    }

    // Fetch all user tokens (broadcast)
    const users = await User.find({ fcmTokens: { $exists: true, $not: { $size: 0 } } });
    const tokens = users.flatMap(u => u.fcmTokens);

    if (tokens.length === 0) return;

    const message = {
      notification: { title, body },
      data,
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ Push notification sent successfully: ${response.successCount} success, ${response.failureCount} failure`);
  } catch (error) {
    console.error('❌ Error sending push notification:', error.message);
  }
};

module.exports = { sendWelcomeEmail, sendPushNotification };
