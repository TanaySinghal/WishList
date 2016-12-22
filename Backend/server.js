// Set up
var hv = require('./hidden_vars.json');
var express = require('express');
var app = express();
var bodyParser = require("body-parser");
var mongoose = require('mongoose');

//Connect to mongo when app initializes
mongoose.connect('mongodb://'+hv.db_user+':'+hv.db_pass+'@'+hv.db_url+'/'+hv.db_name);

//Here we are configuring express to use body-parser as middle-ware.
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// All APIs
// Wish API
var wish_api = require('./controllers/wish_api.js');
app.get('/wish/find_wish_by_user/:owner_id', wish_api.find_wish_by_user);
app.get('/wish/find_public_wish_by_user/:owner_id', wish_api.find_public_wish_by_user);
app.get('/wish/find_one/:wish_id', wish_api.find_one);
app.post('/wish/create', wish_api.create);
app.get('/wish/delete/:wish_id', wish_api.delete);

// User API
var user_api = require('./controllers/user_api.js');
app.post('/user/authorize_from_fb', user_api.authorize_from_fb);
app.get('/user/find_by_id/:user_id', user_api.find_by_id);
app.post('/user/update/:user_id', user_api.update);
app.post('/user/add_friend', user_api.add_friend);
app.post('/user/remove_friend', user_api.remove_friend);

app.post('/user/send_friend_request', user_api.send_friend_request);
app.get('/user/friend_request_count/:user_id', user_api.friend_request_count);
app.get('/user/list_friend_requests/:user_id', user_api.list_friend_requests);
app.post('/user/remove_friend_request', user_api.remove_friend_request);
app.post('/user/accept_friend_request', user_api.accept_friend_request);
// End all APIs

// Application
app.use(express.static(__dirname + '/public'));

// Start app (listen on port 3000)
var port = 8080;
app.listen(port, function() {
  console.log("App listening on port " + port);
});
