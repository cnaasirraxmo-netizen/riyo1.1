const { S3Client } = require('@aws-sdk/client-s3');
const dotenv = require('dotenv');

dotenv.config();

const r2Endpoint = process.env.R2_S3_ENDPOINT || (process.env.R2_ACCOUNT_ID ? `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com` : 'https://missing-endpoint.com');
const r2Configured = !!(process.env.R2_ACCESS_KEY_ID && process.env.R2_SECRET_ACCESS_KEY && (process.env.R2_S3_ENDPOINT || process.env.R2_ACCOUNT_ID));

const r2Client = new S3Client({
  region: 'auto',
  endpoint: r2Endpoint,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID || 'missing',
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || 'missing',
  },
});

if (r2Configured) {
  console.log('📡 R2 Client initialized with endpoint:', process.env.R2_S3_ENDPOINT);
} else {
  console.warn('📡 R2 Storage is not fully configured. Check your environment variables.');
}

module.exports = { r2Client };
