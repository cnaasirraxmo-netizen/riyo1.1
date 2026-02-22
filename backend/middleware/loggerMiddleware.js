const AuditLog = require('../models/AuditLog');

const loggerMiddleware = async (req, res, next) => {
  const originalSend = res.send;

  res.send = function(data) {
    if (req.user && req.user.role !== 'user' && ['POST', 'PUT', 'DELETE'].includes(req.method)) {
        // Record admin actions asynchronously
        AuditLog.create({
            admin: req.user._id,
            action: `${req.method}_${req.url.split('/')[1].toUpperCase()}`,
            module: req.url.split('/')[1],
            targetId: req.params.id,
            details: JSON.stringify(req.body),
            ipAddress: req.ip,
            userAgent: req.headers['user-agent']
        }).catch(err => console.error('Logging failed', err));
    }

    return originalSend.apply(res, arguments);
  };

  next();
};

module.exports = { loggerMiddleware };
