var wishlist = angular.module('wishlist', []);

wishlist.controller('mainController', [
'$scope', '$http',
function($scope, $http) {

  $http.get('/wish/find_all')
      .success(function(data) {
          $scope.wishes = data;
          console.log(data);
      })
      .error(function(data) {
          console.log('Error: ' + data);
      });

  // when submitting the add form, send the text to the node API
  $scope.createWish = function() {
      $http.post('/wish/create', $scope.formData)
          .success(function(data) {
              // clear the form so our user is ready to enter another
              $scope.formData = {};
              $scope.wishes = data;
              console.log(data);
          })
          .error(function(data) {
              console.log('Error: ' + data);
          });
  };

  // delete a wish after checking it
  $scope.deleteWish = function(id) {
      $http.get('/wish/delete/' + id)
          .success(function(data) {
              $scope.wishes = data;
              console.log(data);
          })
          .error(function(data) {
              console.log('Error: ' + data);
          });
  };

}]);
