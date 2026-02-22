
const User = require('../models/User');
const AppSetting = require('../models/AppSetting');

const geoBlock = async (req, res, next) => {
  try {
    const geoRestricted = await AppSetting.findOne({ key: 'geo_restricted_countries' });
    if (!geoRestricted || !geoRestricted.value || geoRestricted.value.length === 0) {
      return next();
    }

    // In production, use req.headers['cf-ipcountry'] or a geoip library
    // For now, we simulate country detection
    const userCountry = req.headers['x-user-country'] || 'US';

    if (geoRestricted.value.includes(userCountry)) {
      return res.status(403).json({
        message: 'RIYOBOX is not available in your region yet.',
        blockedCountry: userCountry
      });
    }

    next();
  } catch (error) {
    next();
  }
};

module.exports = { geoBlock };
