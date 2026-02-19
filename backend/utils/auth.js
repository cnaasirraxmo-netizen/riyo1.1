const jwt = require('jsonwebtoken');

const generateAccessToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '1h' });
};

const generateRefreshToken = (id, rememberMe = false) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: rememberMe ? '30d' : '7d' });
};

const validatePassword = (password) => {
  const minLength = 8;
  const hasUppercase = /[A-Z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecialChar = /[!@#$%^&*(),.?":{}|<>]/.test(password);

  return (
    password.length >= minLength &&
    hasUppercase &&
    hasNumber &&
    hasSpecialChar
  );
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  validatePassword
};
