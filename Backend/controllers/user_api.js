//This creates a collection or updates it
var User = require('../models/user.js');
var hf = require('../helper_functions.js');

// Documentation:
// - authorize_from_fb (post) logs in or registers a user using Facebook information
// - remove (get) deletes an account and all its interactions
// - find_by_id (get) searches for a user by their id
// - update (post) updates a user's profile given information to update
// - search (post) searches for users given search text

// - list_friends (get) lists a user's friends
// - remove_friend (post) removes a user's friend

// - send_friend_request (post) sends a friend request from one user to another
// - friend_request_count (get) counts the number of friend requests a user has
// - list_friend_requests (get) lists a user's friend requests
// - remove_friend_request (post) removes a user's friend request
// - accept_friend_request (post) accepts a user's friend request

// Implementation:
// Post request
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

// Get request
exports.remove = function (req, res) {

    User.findOne({_id: req.params.user_id}, function (err, user) {
        if (err) {
					res.send("ERROR \n" + err);
					return;
        }

        user.remove();
				// Don't know what to return
				res.json(user);
    });

}

// Get request
exports.find_by_id = function (req, res) {

  User.findOne({_id: req.params.user_id})
	.select('+friends')
	.populate('friends')
	.exec(function (err, user) {
		if (err) res.send("ERROR \n" + err);
    res.send(user);
  });

}

// Post request
/*{
  "username": "fbondi",
  "about_me": "I am cool"
}*/
exports.update = function(req, res) {
	var query = {
		_id: {$eq: req.body.user_id}
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

	User.update(query, {$set: updateTo})
	.exec(function (err, result) {
		if(err) res.send("ERROR: \n" + err);

		res.send(result);
	});
}

// Post request
/*{
	"searcher_id": "...",
	"search_text": "Tanay"
}*/
exports.search = function (req, res) {

	var searcher_id = req.body.searcher_id;
	var search_text = req.body.search_text;

	var query = {
		$or: [
			 {username: { "$regex": search_text, "$options": "i" }},
			 {first_name: { "$regex": search_text, "$options": "i" }},
			 {last_name: { "$regex": search_text, "$options": "i" }}
		 ]
	 };

	User.find(query)
	.lean() // Return a native JavaScript JSON object
	.limit(20) // Limit to 20 search results
	.exec(function (err, users) {
			if(err) {
				res.send("ERROR: \n" + err);
				return;
			}

			var usersJSON = users;

			// Add profile state to usersJson
			for(var i = 0; i < usersJSON.length; i++) {
				// Get profile state
				var profileState = hf.getProfileState(usersJSON[i], searcher_id);

				usersJSON[i].profile_state = profileState;

				if (profileState == "strangerProfile") {
					// Get stranger state
					var friend_requests = usersJSON[i].friend_requests;
					var sent_friend_requests = usersJSON[i].sent_friend_requests;
					var strangerState = hf.getStrangerState(friend_requests, sent_friend_requests, searcher_id);
					usersJSON[i].stranger_state = strangerState;
				}

			}

			res.json(usersJSON);
	});
}

// MARK - Friends
// Get request
exports.list_friends = function (req, res) {
	var user_id = req.params.user_id;

	User.findOne({_id: user_id}, function (err, user) {
			if(err) {
				res.send("ERROR: \n" + err);
				return;
			}

			res.json(user.friends);
	}).populate('friends');
}


// Post request
/*{
  "user_id": "....",
  "friend_id": "...."
}*/
exports.remove_friend = function (req, res) {
	var user_id = req.body.user_id;
	var friend_id = req.body.friend_id;

	// Search for users
	var query = {
  		$or: [
  			{ _id: user_id },
  			{ _id: friend_id }
  		]
	};

	// Remove each other as friends
	var action = {
		$pull: {
			friends: { $in: [ user_id, friend_id] }
		}
	};

	User.update(query, action, {"multi": true}, function (err, user) {

		if(err) {
			res.send("ERROR: \n" + err);
			return;
		}

		User.findOne({_id: friend_id}, function (err, friend) {
				if(err) {
					res.send("ERROR: \n" + err);
					return;
				}

				// Send unfriended friend
				res.json(friend);

		});
	});
}


// MARK - Friend Requests
// Post request
// Sample json:
/*{
  "sender_id": "....",
  "user_id": "...."
}*/
exports.send_friend_request = function(req, res) {
		var sender_id = req.body.sender_id;
		var user_id = req.body.user_id;

		var query1 = {
			_id: sender_id,
			// Make sure we're not already friends
			friends: {$ne: user_id},
			// Make sure I haven't received a request already
			friend_requests: {$ne: user_id},
			// Make sure I haven't sent a request already
			sent_friend_requests: {$ne: user_id}
		}

		var update1 = {
			// Add that I sent them a friend request
			$addToSet: { sent_friend_requests: user_id }
		}

		User.update(query1, update1, function (err, sender) {

			if(err) {
				res.send("ERROR: \n" + err);
				return;
			}

			var query2 = {
				_id: user_id,
				// Make sure we're not already friends
				friends: {$ne: sender_id},
				// Make sure they haven't received a request from me already
				friend_requests: {$ne: sender_id},
				// Make sure they haven't sent a request to me already
				sent_friend_requests: {$ne: sender_id}
			}
			var update2 = {
				// Send them a friend request
		    $addToSet: { friend_requests: sender_id }
			}

			User.update(query2, update2, function(err, user) {
					if(err) {
						res.send("ERROR: \n" + err);
						return;
					}

					// Return user who we sent the friend request to
					res.json(user);
			});
		});
}

// Get request
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

// Get request
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


// Post request
// Sample json:
/*{
  "sender_id": "....",
  "user_id": "...."
}*/
exports.remove_friend_request = function (req, res) {
		var user_id = req.body.user_id;
		var sender_id = req.body.sender_id;

		// Search for users
		var query = {
	  		$or: [
	  			{ _id: sender_id },
	  			{ _id: user_id }
	  		]
		};

		// Remove sent and received request
		var action = {
			$pull: {
				// Remove user_id from sender's sent_friend_requests
				sent_friend_requests: user_id,
				// Remove sender_id from user's friend_requests
				friend_requests: sender_id
			}
		};

		User.update(query, action, {"multi": true}, function (err, sender) {

			if(err) {
				res.send("ERROR: \n" + err);
				return;
			}

			// Return new list of friend requests
			User.findOne({_id: user_id}, function(err, user) {
				res.json(user.friend_requests);
			}).populate('friend_requests');

		});
}

// Post request
// Sample json:
/*{
  "sender_id": "....",
  "user_id": "...."
}*/
exports.accept_friend_request = function(req, res) {

	// Make sure not already friends...
	var user_id = req.body.user_id;
	var sender_id = req.body.sender_id;

	// Can't do new method because addToSet would add two friends to both

	// Search for sender
	var query1 = {
		_id: sender_id,
		// If not friends already
		friends: {$ne: user_id},
		// And if sender has sent a request
		sent_friend_requests: {$eq: user_id}
	}
	var action1 = {
		// Remove user from sender's sent friend requests
		$pull: { sent_friend_requests: user_id },
		// Add user as friend
		$addToSet: { friends: user_id }
	}

	User.update(query1, action1, {"multi": true}, function (err, sender) {

		if(err) {
			res.send("ERROR: \n" + err);
			return;
		}

		// Search for my user
		var query2 = {
			_id: user_id,
			// If not friends already
			friends: {$ne: sender_id},
			// And if user has received a request
			friend_requests: {$eq: sender_id}
		}
		var action2 = {
			// Remove sender from user's friend requests
			$pull: { friend_requests: sender_id },
			// Add sender as friend
			$addToSet: { friends: sender_id }
		}

		User.findOneAndUpdate(query2, action2, {"multi": true}, function (err, user) {
				if(err) {
					res.send("ERROR: \n" + err);
					return;
				}

				// Return new list of friend requests
				User.findOne({_id: user_id}, function(err, user) {
					res.json(user.friend_requests);
				}).populate('friend_requests');

		})
	});
}
