const request = require('supertest');
const express = require('express');
const sportsRouter = require('./routes/sports');

// Mock middleware
const protect = (req, res, next) => {
  req.user = { _id: 'mockuser', role: 'user' };
  next();
};

jest.mock('./middleware/authMiddleware', () => ({
  protect: jest.fn((req, res, next) => {
    req.user = { _id: 'mockuser', role: 'user' };
    next();
  })
}));

const app = express();
app.use(express.json());
app.use('/sports', sportsRouter);

describe('Sports API', () => {
  it('should be defined', () => {
    expect(sportsRouter).toBeDefined();
  });
});
