//This creates a collection or updates it
var User = require('../models/user.js');
var hf = require('../helper_functions.js');

// Methods we have:
// - authorize_from_fb,
// - find_by_id,
// - update,
// - add_friend,
// - remove_friend

// Untested methods:
// - send_friend_request (post),
// - friend_request_count (get)
// - list_friend_requests (get),
// - remove_friend_request (post),
// - accept_friend_request (post)

// post request
/*{
	"fb_user_id": "...",
  "first_name": "Francesco",
  "last_name": "Bondi",
  "username": "fbondi",
  "email": "fbondi@lol.com"
}*/
exports.authorize_from_fb = function (req, res) {
	// if FB user id is exists... login
	// else, register them
	var _fb_user_id = req.body.fb_user_id;

	User.find({fb_user_id : _fb_user_id}, function (err, users) {
		if (err) {
			res.send("ERROR \n" + err);
			return;
		}

		// if user does not exist, register them
		 if (users.length == 0){
			 	var new_user = new User({
			 		fb_user_id: _fb_user_id,
			 		first_name: req.body.first_name,
			 		last_name: req.body.last_name,
			 		username: req.body.username,
			 		email: req.body.email
			 	});

			 	new_user.save(function (err, new_user) {
					if (err) {
						res.send("ERROR \n" + err);
						return;
					}

			     var str = "Registering user with ID " + new_user._id + " and username " + new_user.username;
			     console.log(str);
			     res.send(new_user);
			 	});
		 }
		 // else, log them in
		 else if (users.length == 1) {
			 // login
			 res.send(users[0]);
		 }
		 else {
			 res.send("ERROR FB ID is not unique.");
		 }
	});
}

exports.find_by_id = function (req, res) {

  User.findOne({_id: req.params.user_id})
	.select('+friends')
	.populate('friends')
	.exec(function (err, user) {
		if (err) res.send("ERROR \n" + err);
    res.send(user);
  });

}


exports.update = function(req, res) {
	var user = {
		_id: {$eq: req.params.user_id}
	};

	// NOTE: Not allowed to change username once it has been set
	var _username = req.body.username;
	var _first_name = req.body.first_name;
	var _last_name = req.body.last_name;
	var _about_me = req.body.about_me;
	var _address = req.body.address;

	//Empty JSON
	var updateTo = {};

	if (_username) updateTo.username = _username;
	if (_first_name) updateTo.first_name = _first_name;
	if (_last_name) updateTo.last_name = _last_name;
	if (_about_me) updateTo.about_me = _about_me;
	if (_address) updateTo.address = _address;

	User.update(user, {$set: updateTo})
	.exec(function (err, result) {
		if(err) res.send("ERROR: \n" + err);

		res.send(result);
	});
}

// MARK - Friends
// GET friends
exports.list_friend_requests = function (req, res) {
	var user_id = req.params.user_id;

	User.findOne({_id: user_id}, function (err, user) {
			if(err) {
				res.send("ERROR: \n" + err);
				return;
			}

			res.json(user.friends);
	}).populate('friends');
}


// Sample json:
/*{
  "user_id": "....",
  "friend_id": "...."
}*/
exports.add_friend = function (req, res) {
	var user_id = req.body.user_id;
	var friend_id = req.body.friend_id;

	// Search for this user
	User.findOne({_id : user_id}, function(err, user) {
		if(err) {
			res.send("ERROR: \n" + err);
			return;
		}

		// Search for friend
		User.findOne({_id: friend_id}, function (err, friend) {
			if(err) {
				res.send("ERROR: \n" + err);
				return;
			}

			// Check if already friends
			if (hf.contains(user.friends, friend._id) ||
					hf.contains(friend.friends, user._id)) {
					res.send("Already friends.");
					return;
			}

			// Add each other as friends
			user.friends.push(friend._id);
			friend.friends.push(user._id);

			// Update users
			friend.save();
			user.save();

			res.send(user);
		});

	});
}

// Sample json:
/*{
  "user_id": "....",
  "friend_id": "...."
}*/
exports.remove_friend = function (req, res) {
	var user_id = req.body.user_id;
	var friend_id = req.body.friend_id;

	// Search for this user
	User.findOne({_id : user_id}, function(err, user) {
		if(err) {
			res.send("ERROR: \n" + err);
			return;
		}

		// Search for friend
		User.findOne({_id: friend_id}, function (err, friend) {
			if(err) {
				res.send("ERROR: \n" + err);
				return;
			}

			// Check if already not friends
			if (!(hf.contains(user.friends, friend._id) &&
					hf.contains(friend.friends, user._id))) {
					res.send("Already not friends.");
					return;
			}

			// Remove each other as friends
			user.friends.pull(friend._id);
			friend.friends.pull(user._id);

			// Update users
			friend.save();
			user.save();

			res.send(user);
		});

	});
}


// MARK - Friend Requests
// Sample json:
/*{
  "from_user_id": "....",
  "to_user_id": "...."
}*/
exports.send_friend_request = function(req, res) {
		var from_user_id = req.body.from_user_id;
		var to_user_id = req.body.to_user_id;

		User.findOne({_id: to_user_id}, function (err, to_user) {
				if(err) {
					res.send("ERROR: \n" + err);
					return;
				}

				to_user.friend_requests.push(from_user_id);
				to_user.save();

				// Don't know what to return, so I'll just return to_user
				res.json(to_user);
		});
}

// GET request
exports.friend_request_count = function (req, res) {
	var user_id = req.params.user_id;

	User.findOne({_id: user_id}, function (err, user) {
			if(err) {
				res.send("ERROR: \n" + err);
				return;
			}

			var customJson = {"friend_request_count": user.friend_requests.length};
			res.json(customJson);
	});
}

// GET request
exports.list_friend_requests = function (req, res) {
	var user_id = req.params.user_id;

	User.findOne({_id: user_id}, function (err, user) {
			if(err) {
				res.send("ERROR: \n" + err);
				return;
			}

			res.json(user.friend_requests);
	}).populate('friend_requests');
}


// Sample json:
/*{
  "sender_id": "....",
  "user_id": "...."
}*/
exports.remove_friend_request = function (req, res) {
		var sender_id = req.body.sender_id;
		var user_id = req.body.user_id;

		User.findOne({_id: user_id}, function (err, user) {
				if(err) {
					res.send("ERROR: \n" + err);
					return;
				}

				if (!(hf.contains(user.friend_requests, sender_id))) {
						res.send("Friend request is non-existant");
						return;
				}

				user.friend_requests.pull(sender_id);
				user.save();

				// Return new list of friend requests
				res.json(user.friend_requests);
		}).populate('friend_requests');
}


// Sample json:
/*{
  "sender_id": "....",
  "user_id": "...."
}*/
exports.accept_friend_request = function(req, res) {
		var sender_id = req.body.sender_id;
		var user_id = req.body.user_id;

		User.findOne({_id: user_id}, function (err, user) {
				if(err) {
					res.send("ERROR: \n" + err);
					return;
				}

				// Remove friend request
				if (!(hf.contains(user.friend_requests, sender_id))) {
						res.send("Friend request is non-existant");
						return;
				}

				user.friend_requests.pull(sender_id);

				// Add friends... search for sender first
				User.findOne({_id: sender_id}, function (err, sender) {
					if(err) {
						res.send("ERROR: \n" + err);
						return;
					}

					// Check if already friends
					if (hf.contains(user.friends, sender._id) ||
							hf.contains(sender.friends, user._id)) {
							res.send("Error: already friends.");
							return;
					}

					// Add each other as friends
					user.friends.push(sender._id);
					sender.friends.push(user._id);

					// Update users
					sender.save();
					user.save();

					// Return new list of friend requests
					res.json(user.friend_requests);
				});
		}).populate('friend_requests');
}
