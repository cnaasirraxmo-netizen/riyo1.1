const express = require('express');
const multer = require('multer');
const axios = require('axios');
const { ListObjectsV2Command, DeleteObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { Upload } = require('@aws-sdk/lib-storage');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { r2Client } = require('../utils/r2Config');
const { protect, adminOnly } = require('../middleware/authMiddleware');
const router = express.Router();

const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: {
    fileSize: 1024 * 1024 * 1024, // 1GB limit for videos
  }
});

const getBaseUrl = () => {
  if (process.env.R2_PUBLIC_URL) return process.env.R2_PUBLIC_URL;
  return `${process.env.R2_S3_ENDPOINT}/${process.env.R2_BUCKET_NAME}`;
};

// Upload file to R2
router.post('/', protect, adminOnly, upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'No file uploaded' });

  const fileName = `${Date.now()}-${req.file.originalname.replace(/\s+/g, '_')}`;
  const contentType = req.file.mimetype;

  try {
    const parallelUploads3 = new Upload({
      client: r2Client,
      params: {
        Bucket: process.env.R2_BUCKET_NAME,
        Key: fileName,
        Body: req.file.buffer,
        ContentType: contentType,
      },
      queueSize: 4,
      partSize: 1024 * 1024 * 5, // 5MB parts
      leavePartsOnError: false,
    });

    await parallelUploads3.done();

    const publicUrl = `${getBaseUrl()}/${fileName}`;

    res.status(201).json({
      message: 'File uploaded successfully',
      url: publicUrl,
      key: fileName
    });
  } catch (error) {
    console.error('R2 Upload Error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Upload from URL (e.g. for posters)
router.post('/by-url', protect, adminOnly, async (req, res) => {
  const { url } = req.body;
  if (!url) return res.status(400).json({ message: 'URL is required' });

  try {
    const response = await axios.get(url, { responseType: 'arraybuffer' });
    const contentType = response.headers['content-type'];
    const extension = contentType.split('/')[1] || 'jpg';
    const fileName = `url-${Date.now()}.${extension}`;

    const parallelUploads3 = new Upload({
      client: r2Client,
      params: {
        Bucket: process.env.R2_BUCKET_NAME,
        Key: fileName,
        Body: response.data,
        ContentType: contentType,
      },
    });

    await parallelUploads3.done();
    const publicUrl = `${getBaseUrl()}/${fileName}`;

    res.status(201).json({
      message: 'File uploaded from URL successfully',
      url: publicUrl,
      key: fileName
    });
  } catch (error) {
    console.error('URL Upload Error:', error);
    res.status(500).json({ message: error.message });
  }
});

// List all objects in R2 bucket
router.get('/', protect, adminOnly, async (req, res) => {
  try {
    const data = await r2Client.send(
      new ListObjectsV2Command({
        Bucket: process.env.R2_BUCKET_NAME,
      })
    );

    const baseUrl = getBaseUrl();
    const files = data.Contents?.map(file => ({
      key: file.Key,
      size: file.Size,
      lastModified: file.LastModified,
      url: `${baseUrl}/${file.Key}`
    })) || [];

    res.json(files);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Delete an object from R2
router.delete('/:key', protect, adminOnly, async (req, res) => {
  try {
    await r2Client.send(
      new DeleteObjectCommand({
        Bucket: process.env.R2_BUCKET_NAME,
        Key: req.params.key,
      })
    );
    res.json({ message: 'File deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Generate a signed URL for an object (valid for 1 hour)
router.get('/signed-url/:key', protect, async (req, res) => {
  try {
    const command = new GetObjectCommand({
      Bucket: process.env.R2_BUCKET_NAME,
      Key: req.params.key,
    });
    const url = await getSignedUrl(r2Client, command, { expiresIn: 3600 });
    res.json({ url });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
