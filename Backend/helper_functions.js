
// contains: [Any], Any -> Bool
// Example:
// hf.contains(array, item);
exports.contains = function (array, item) {
  return array.indexOf(item) != -1;
}


// contains: JSONArray, Item -> Bool
// Example:
// hf.jsonContains(array, item);
exports.jsonContains = function (jsonArray, item) {

  for(var i = 0; i < jsonArray.length; i++) {
      if (jsonArray[i] == item) {
          return true;
      }
  }

  return false;
}

exports.getProfileState = function (userJSON, searcherId) {

  // Add profile state to usersJson
	if (userJSON._id == searcherId) {
		return "myProfile";
	}
	else if (this.jsonContains(userJSON.friends, searcherId)) {
		return "friendProfile";
	}
	else {
		return "strangerProfile";
	}
}

exports.getStrangerState = function (strangerFriendRequests, strangerSentFriendRequests, myUserId) {

  for(var i = 0; i < strangerFriendRequests.length; i ++) {
  	if (strangerFriendRequests[i] == myUserId) {
  		return "sent";
  	}
  }

  for(var i = 0; i < strangerSentFriendRequests.length; i ++) {
  	if (strangerSentFriendRequests[i] == myUserId) {
  		return "received";
  	}
  }

  return "none";
}
