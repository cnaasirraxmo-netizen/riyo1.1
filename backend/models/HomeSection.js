const mongoose = require('mongoose');

const homeSectionSchema = new mongoose.Schema({
  title: { type: String, required: true },
  type: { type: String, enum: ['trending', 'top_rated', 'new_releases', 'continue_watching', 'genre'], required: true },
  genre: { type: String }, // Used if type is 'genre'
  order: { type: Number, default: 0 },
}, { timestamps: true });

module.exports = mongoose.model('HomeSection', homeSectionSchema);
