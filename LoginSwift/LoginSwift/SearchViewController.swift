//
//  SearchViewController.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/22/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit
import Alamofire

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // Check this out: https://www.raywenderlich.com/113772/uisearchcontroller-tutorial
    
    struct SearchResult {
        var id: String
        var fbUserId: String
        var fullName: String
        var username: String
        var image: UIImage?
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var searchResults = [SearchResult]()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    // Some notes:
    // The way image "caching" kind of works is: if the old search had the same user, use that image
    
    // But we want to improve this..
    // TODO: Store an association list (username, image), sorted by username of a maximum length of 20. 
        // For each new search result, check if it is in association list (using binary search)
        // If so, then set it to that image. Otherwise don't
        // We now no longer need to store "image" in SearchResult
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        searchController.searchResultsUpdater = self
        //searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        tableView.tableHeaderView = searchController.searchBar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Define some random stuff
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Search
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        // Stream data in background queue
        DispatchQueue.global().async {
            
            // Send POST request to find search results
            let parameters: Parameters = [
                "search_text": searchText
            ]
            
            Alamofire.request("http://localhost:8080/user/search", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                // New code
                switch response.result {
                case .success(let value):
                    if let JSON = response.result.value {
                        self.refreshTableWithJson(JSON: JSON)
                    }
                    else {
                        print("Failed to serialize JSON in SearchVC. Here is the result: \(value)")
                    }
                    
                case .failure(let error):
                    print("Get request from SearchVC failed: \(error)")
                }
            }
            
        }
        
    }
    
    
    // MARK:
    func refreshTableWithJson(JSON: Any) {
        
        
        // Remember old search result. When you update, only update images that are new
        let oldSearchResults = searchResults
        
        // Reset friendDetails
        searchResults = [SearchResult]()
        
        // Go through array
        if let jsonArray = JSON as? NSMutableArray {
            
            let parser = JSONParser()
            
            for jsonObject in jsonArray {
                
                // Extract information
                let id = parser.parseJsonAsString(json: jsonObject as AnyObject, field: "_id")
                let fbUserId = parser.parseJsonAsString(json: jsonObject as AnyObject, field: "fb_user_id")
                let firstName = parser.parseJsonAsString(json: jsonObject as AnyObject, field: "first_name")
                let lastName = parser.parseJsonAsString(json: jsonObject as AnyObject, field: "last_name")
                let fullName = firstName! + " " + lastName!
                let username = parser.parseJsonAsString(json: jsonObject as AnyObject, field: "username")
                
                // Create new WishDetail
                let newSearchResults = SearchResult(
                    id: id!,
                    fbUserId: fbUserId!,
                    fullName: fullName,
                    username: username!,
                    image: nil
                )

                
                searchResults.append(newSearchResults)
            }
            
            // Update image in search results that we already had from old search results
            for i in 0...(searchResults.count - 1) {
                
                // If this is in old search results, update image
                if let result = usernameInSearchResults(targetUsername: searchResults[i].username, results: oldSearchResults) {
                    
                    searchResults[i].image = result.image
                    
                }
            }
            
            
        }
        else if JSONSerialization.isValidJSONObject(JSON) {
            // There are no friend requests..
        }
        else {
            print("FriendsVC: JSON is not valid. Here is the JSON: \(JSON)")
        }
        
        
        // Reload table to see change
        DispatchQueue.main.async{
            self.reloadTable()
        }
    }
    
    
    
    func usernameInSearchResults(targetUsername: String, results: [SearchResult]) -> SearchResult? {
        // Binary search algorithm
        var min = 0
        var max = results.count - 1
        
        while (true) {
            if min > max {
                return nil
            }
            
            let guess = (min+max)/2
            let usernameAtGuess = results[guess].username
            
            if usernameAtGuess == targetUsername {
                return results[guess]
            }
            if usernameAtGuess < targetUsername {
                min = guess + 1
                continue
            }
            if usernameAtGuess > targetUsername {
                max = guess - 1
                continue
            }
        }
    }
    
    // MARK: - Table View
    func reloadTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchResultCell") as! SearchResultCell
        
        let row = indexPath.row
        
        let fbUserId = searchResults[row].fbUserId
        
        if searchResults[row].image == nil {
            
            HelperFunctions().loadImageFromFacebookWithCompletion(facebookUserId: fbUserId, width: 200, height: 200) { image in
                
                print("Loading image")
                cell.profileImage.image = image
                self.searchResults[row].image = image
            }
    
        }
        else {
            cell.profileImage.image = searchResults[row].image
        }
        cell.nameLabel.text = searchResults[row].fullName
        cell.usernameLabel.text = searchResults[row].username
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    
    deinit {
        //remove search controller
        searchController.view!.removeFromSuperview()
    }

    //searchResultCell
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}



/*extension SearchViewController: UISearchBarDelegate {
    // MARK: - UISearchResultsUpdating Delegate
    func searchBar(searchBar: UISearchBar) {
        filterContentForSearchText(searchText: searchBar.text!)
    }
}*/

extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}


