const express = require('express');
const router = express.Router();
const axios = require('axios');

const FOOTBALL_API_URL = 'https://v3.football.api-sports.io';
const API_KEY = process.env.FOOTBALL_API_KEY || 'YOUR_API_KEY';

const headers = {
  'x-apisports-key': API_KEY
};

router.get('/fixtures', async (req, res) => {
  try {
    const { league, season, live } = req.query;
    let params = {};
    if (league) params.league = league;
    if (season) params.season = season;
    if (live) params.live = live;

    const response = await axios.get(`${FOOTBALL_API_URL}/fixtures`, { headers, params });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.get('/standings', async (req, res) => {
  try {
    const { league, season } = req.query;
    const response = await axios.get(`${FOOTBALL_API_URL}/standings`, { headers, params: { league, season } });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.get('/teams', async (req, res) => {
  try {
    const { league, season } = req.query;
    const response = await axios.get(`${FOOTBALL_API_URL}/teams`, { headers, params: { league, season } });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.get('/players', async (req, res) => {
  try {
    const { league, season, team } = req.query;
    let params = {};
    if (league) params.league = league;
    if (season) params.season = season;
    if (team) params.team = team;

    const response = await axios.get(`${FOOTBALL_API_URL}/players`, { headers, params });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.get('/topscorers', async (req, res) => {
  try {
    const { league, season } = req.query;
    const response = await axios.get(`${FOOTBALL_API_URL}/players/topscorers`, { headers, params: { league, season } });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
