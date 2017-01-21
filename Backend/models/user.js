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
  about_me: String,
  address: String,

  friends: [{type: Schema.ObjectId, ref: "User"}],
  wishes: [{ type: Schema.ObjectId, ref: "Wish"}],

  // From user
  friend_requests: [{ type: Schema.ObjectId, ref: "User"}],
  // To user
  sent_friend_requests: [{ type: Schema.ObjectId, ref: "User"}],

	create_date: { type: Date, default: Date.now}
});

// Test again
userSchema.pre('remove', function(next) {
  
  var User = mongoose.model('User', userSchema, 'user');
  var Wish = mongoose.model('Wish', userSchema, 'wish');
  console.log("Doing remove hook");

  var user_id = this._id;

	var user_query = {
		$or: [
			{ friend_requests: { $eq : user_id } },
			{ sent_friend_requests: { $eq : user_id } },
			{ friends: { $eq : user_id } }
		]
	};

	var user_action = {
		$pull: {
			sent_friend_requests: user_id,
			friend_requests: user_id,
			friends: user_id
		}
	};

  // Update all users that match query with action
  User.update(user_query, user_action, {"multi": true}, next);

  // Remove all their wishes - needs testing
  var wish_query = {
    owner: user_id
  }
  Wish.remove(wish_query, next);
});

module.exports = mongoose.model('User', userSchema, 'user');
