var mongoose = require('mongoose');
var Schema = mongoose.Schema;

var wishSchema = new Schema({
  // owner
  owner: { type: Schema.ObjectId, ref: "User"},
  text: String,
  description: String,
  // public or private
  is_private: Boolean,
	post_date: { type: Date, default: Date.now}
});

module.exports = mongoose.model('Wish', wishSchema, 'wish');
