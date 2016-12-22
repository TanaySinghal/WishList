//This creates a collection or updates it
var Wish = require('../models/wish.js');
var User = require('../models/user.js');

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


exports.find_one = function(req, res) {
  // Return list
  Wish.findOne({_id: req.params.wish_id})
  .populate('owner')
  .exec(function (err, wishes) {
    if (err) res.send("ERROR \n" + err);
    res.json(wishes);
  });
}


/*{
  "owner": "owner_id",
  "text": "Cute Puppy",
  "description": "Preferably smol",
  "is_private": false
}*/
exports.create = function (req ,res) {

  var _owner = req.body.owner;

  var wish = new Wish({
      owner: _owner,
      text: req.body.text,
      description: req.body.description,
      is_private: req.body.is_private
  });


  wish.save(function (err, wish) {
    if (err) {
      res.send("ERROR \n" + err);
      return;
    }

    var str = "Added wish with ID " + wish._id + " and text " + wish.text;
    console.log(str);

    // Add wish to user's wish list
    User.findOne({_id: _owner}, function (err, user) {
      if (err) {
        res.send("ERROR \n" + err);
        return;
      }

      user.wishes.push(wish._id);
      user.save();

      // Return list of wishes
      Wish.find(function (err, wishes) {
        if (err) {
          res.send("ERROR \n" + err);
          return;
        }
        res.json(wishes);
      });
    });
  });
}


exports.delete = function (req ,res) {
  // Find wish
  Wish.findOne({_id: req.params.wish_id}, function (err, wish){

    // Remove wish
    wish.remove();

    // Find user
    User.findOne({_id: wish.owner}, function (err, user) {
      if (err) res.send("ERROR \n" + err);

      // Remove wish from user
      user.wishes.pull(wish._id);
      user.save();

      var str = "Removed wish with ID " + wish._id + " from owner " + user._id;
      console.log(str);

      // Return list of wishes
      Wish.find(function (err, wishes) {
        if (err) res.send("ERROR \n" + err);
        res.json(wishes);
      });
    });

  });
}
