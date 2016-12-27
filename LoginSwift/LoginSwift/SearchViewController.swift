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

    
    var searchResults = [ProfileDetail]()
    
    var userId: String?
    
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
        userId = UserDefaults.standard.string(forKey: "user_id")
        
        // Set up search controller
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        // Get initial 20 searches
        sendSearchRequest(searcherId: userId!, searchText: "")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.tableHeaderView = searchController.searchBar
        
        // Reload table in case sending the request couldn't
        reloadTable()
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
            self.sendSearchRequest(searcherId: self.userId!, searchText: searchText)
        }
        
    }
    
    func sendSearchRequest(searcherId: String, searchText: String) {
        
        let parameters: Parameters = [
            "searcher_id": searcherId,
            "search_text": searchText
        ]
        
        let urlPath = "/user/search"
        
        HelperFunctions().sendPostRequest(urlPath: urlPath, parameters: parameters) {
            JSON, errorDescription in
            
            if let json = JSON {
                self.refreshTableWithJson(JSON: json)
            }
            if let error = errorDescription {
                
                // Display alert message
                HelperFunctions().displayAlertMessage(title: "Something went wrong", message: error, viewController: self)
            }
        }
    }
    
    func refreshTableWithJson(JSON: Any) {
        
        
        // Reset friendDetails
        searchResults = [ProfileDetail]()
        
        // Go through array
        if let jsonArray = JSON as? NSMutableArray {
            
            let parser = JSONParser()
            
            for jsonObject in jsonArray {
                
                // Extract information
                let json = jsonObject as AnyObject
                
                let id = parser.parseJsonAsString(json: json, field: "_id")
                let fbUserId = parser.parseJsonAsString(json: json, field: "fb_user_id")
                let firstName = parser.parseJsonAsString(json: json, field: "first_name")
                let lastName = parser.parseJsonAsString(json: json, field: "last_name")
                let fullName = firstName! + " " + lastName!
                let username = parser.parseJsonAsString(json: json, field: "username")
                let profileState = parser.parseJsonAsString(json: json, field: "profile_state")
                let strangerState = parser.parseJsonAsString(json: json, field: "stranger_state")
                let aboutMe = parser.parseJsonAsString(json: json, field: "about_me")
                let address = parser.parseJsonAsString(json: json, field: "address")
                
                
                // Create new search result
                let newSearchResults = ProfileDetail(
                    id: id!,
                    fbUserId: fbUserId!,
                    fullName: fullName,
                    username: username!,
                    aboutMe: aboutMe,
                    address: address,
                    profileState: profileState!,
                    strangerState: strangerState,
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
        if let table = tableView {
            table.delegate = self
            table.dataSource = self
            table.reloadData()
        }
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
    
    deinit {
        //remove search controller
        searchController.view!.removeFromSuperview()
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "searchResultToProfile" {
            if let indexPath = tableView.indexPathForSelectedRow {
                
                let profileVC = segue.destination as! ProfileViewController
                profileVC.profileDetail = searchResults[indexPath.row]
                
            }
        }
        
    }
    
}


extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}



