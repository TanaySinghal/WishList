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
    
    var searchResults = [SearchResult]()
    
    struct Cache {
        var username: String
        var image: UIImage?
    }
    
    var caches = [Cache]()
    let maxCacheSize = 20
    
    @IBOutlet weak var tableView: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Set up search controller
        searchController.searchResultsUpdater = self
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
                
                // Get image from cache
                let username = searchResults[i].username
                searchResults[i].image = getImageInCache(username: username)
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
    
    
    // MARK: - CACHE
    func getImageInCache(username: String) -> UIImage? {
        let cacheResults = caches.filter{$0.username == username}
        if cacheResults.count == 0 {
            return nil
        }
        else if cacheResults.count == 1 {
            return cacheResults[0].image
        }
        else {
            print("ERROR in searchImageInCache: more than 1 matches found for username. Cache results: \(cacheResults)")
            return nil
        }
    }
    
    func addImageToCache(username: String, image: UIImage) {
        let newCache = Cache(username: username, image: image)
        caches.append(newCache)
        
        // Keep caches array limited
        if caches.count > maxCacheSize {
            caches.removeFirst()
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
        
        let username = searchResults[row].username
        let fbUserId = searchResults[row].fbUserId
        
        if searchResults[row].image == nil {
            
            HelperFunctions().loadImageFromFacebookWithCompletion(facebookUserId: fbUserId, width: 200, height: 200) { image in
                
                print("Loading image for username \(username)")
                cell.profileImage.image = image
                self.searchResults[row].image = image
                
                self.addImageToCache(username: username, image: image!)
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}


extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}



