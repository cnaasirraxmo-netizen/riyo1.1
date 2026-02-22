const express = require('express');
const Ticket = require('../models/Ticket');
const { protect, adminOnly } = require('../middleware/authMiddleware');
const router = express.Router();

// Get all tickets (Admin)
router.get('/', protect, adminOnly, async (req, res) => {
  try {
    const tickets = await Ticket.find().populate('user', 'name email').sort({ createdAt: -1 });
    res.json(tickets);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Create a ticket (User)
router.post('/', protect, async (req, res) => {
  try {
    const ticket = await Ticket.create({
      user: req.user._id,
      ...req.body
    });
    res.status(201).json(ticket);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Reply to a ticket
router.post('/:id/reply', protect, async (req, res) => {
  try {
    const ticket = await Ticket.findById(req.params.id);
    if (!ticket) return res.status(404).json({ message: 'Ticket not found' });

    ticket.messages.push({
      sender: req.user._id,
      text: req.body.text,
      attachments: req.body.attachments
    });

    if (req.user.role !== 'user') {
      ticket.status = 'In Progress';
    }

    await ticket.save();
    res.json(ticket);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
