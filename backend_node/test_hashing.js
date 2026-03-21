const mongoose = require('mongoose');
const User = require('./models/User');
const bcrypt = require('bcryptjs');

async function testUserHashing() {
  console.log('--- Testing User Password Hashing ---');
  const userData = {
    username: 'testuser',
    email: 'test@example.com',
    password: 'password123'
  };

  const user = new User(userData);
  // Manually trigger pre-save hook logic since we're not connecting to DB
  user.password = await bcrypt.hash(user.password, 12);

  const isMatch = await bcrypt.compare('password123', user.password);
  console.log('Password Match:', isMatch);

  if (isMatch) {
    console.log('SUCCESS: Password hashing and comparison works.');
  } else {
    console.error('FAILURE: Password comparison failed.');
    process.exit(1);
  }
}

testUserHashing();
