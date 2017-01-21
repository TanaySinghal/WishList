//This creates a collection or updates it
var Wish = require('../models/wish.js');
var User = require('../models/user.js');

// Get request
exports.find_wish_by_user = function(req, res) {
  var query = {owner: req.params.owner_id}

  Wish.find(query, function (err, wishes) {
    if (err) {
      res.send("ERROR \n" + err);
      return;
    }
    res.json(wishes);
  });
}

// Get request
exports.find_public_wish_by_user = function(req, res) {
  var query = {
    owner: req.params.owner_id,
    is_private: false
  }

  Wish.find(query, function (err, wishes) {
    if (err) {
      res.send("ERROR \n" + err);
      return;
    }
    res.json(wishes);
  });
}

// Get request
exports.find_one = function(req, res) {
  // Return list
  Wish.findOne({_id: req.params.wish_id})
  .populate('owner')
  .exec(function (err, wishes) {
    if (err) res.send("ERROR \n" + err);
    res.json(wishes);
  });
}

// Post request
/*{
  "owner": "owner_id",
  "text": "Cute Puppy",
  "description": "Preferably smol",
  "is_private": false
}*/
exports.create = function (req ,res) {

  var wish = new Wish({
      owner: req.body.owner,
      text: req.body.text,
      description: req.body.description,
      is_private: req.body.is_private
  });

  wish.save(function (err, wish) {
    if (err) {
      res.send("ERROR \n" + err);
      return;
    }

		// Add wish to user's list of wishes
  	var action = {
  		$addToSet: { wishes: wish._id }
  	}

  	User.update({_id: wish.owner}, action, function (err, user) {
      if (err) {
        res.send("ERROR \n" + err);
        return;
      }

      // List user's wishes
      Wish.find({owner: wish.owner}, function (err, wishes) {
        if (err) {
          res.send("ERROR \n" + err);
          return;
        }
        res.json(wishes);
      });
    });
  });
}

// Get request
exports.delete = function (req ,res) {

  // Find wish
  Wish.findOne({_id: req.params.wish_id}, function (err, wish) {

    // Remove wish
    wish.remove();

    var action = {
      $pull: { wishes: wish._id }
    }

    User.update({_id: wish.owner}, action, {"multi": true}, function (err, user) {
      if (err) {
        res.send("ERROR \n" + err);
        return;
      }

      // List user's wishes
      Wish.find({owner: wish.owner}, function (err, wishes) {
        if (err) {
          res.send("ERROR \n" + err);
          return;
        }
        res.json(wishes);
      });
    });
  });
}
