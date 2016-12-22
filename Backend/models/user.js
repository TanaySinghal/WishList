var mongoose = require('mongoose');
var Schema = mongoose.Schema;


var userSchema = new Schema({
  fb_user_id: {
    type: String,
    unique: true
  },
  first_name: {
    type: String,
    required: true
  },
  last_name: {
    type: String,
    required: true
  },
  username: {
    type: String,
    unique: true,
    required: true
  },
  email: {
    type: String,
    unique: true,
    required: true
  },
  // optional
  image_url: String,
  about_me: String,
  address: String,

  friends: [{ type: Schema.ObjectId, ref: "User"}],
  wishes: [{ type: Schema.ObjectId, ref: "Wish"}],

  //literally just "from user"
  friend_requests: [{ type: Schema.ObjectId, ref: "User"}],

	create_date: { type: Date, default: Date.now}
});


module.exports = mongoose.model('User', userSchema, 'user');
