const User = require('../models/User');

const updateProfile = async (req, res) => {
  const { username, email, oldPassword, newPassword } = req.body;
  const user = await User.findById(req.user._id);

  if (user) {
    // Validate old password
    const isMatch = await user.comparePassword(oldPassword);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid current password' });
    }

    if (username) user.username = username;
    if (email) user.email = email;
    if (newPassword) user.password = newPassword; // Pre-save hook will hash it

    const updatedUser = await user.save();
    res.json({
      _id: updatedUser._id,
      username: updatedUser.username,
      email: updatedUser.email,
      role: updatedUser.role
    });
  } else {
    res.status(404).json({ message: 'User not found' });
  }
};

const getProfile = async (req, res) => {
  res.json(req.user);
};

module.exports = { updateProfile, getProfile };
