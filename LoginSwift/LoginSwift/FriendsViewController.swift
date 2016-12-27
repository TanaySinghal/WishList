//
//  FriendsViewController.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/22/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit
import Alamofire
import Foundation

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var navBar: UINavigationItem!
    
    
    var friendDetails = [ProfileDetail]()
    var searchedFriendDetails = [ProfileDetail]()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var firstTimeLoad = true
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Set up search controller
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        
        //Add refresh control
        refreshControl.addTarget(self, action: #selector(refreshFromPull), for: .valueChanged)
        
        // Get friends from server
        getFriends()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Get updated friends list whenever view appears
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add refresh controller
        self.tableView.addSubview(refreshControl)
        
        if firstTimeLoad {
            firstTimeLoad = false
            // In case getFriends() didn't reload table
            reloadTable()
        }
        else {
            getFriends()
        }
    }
    
    func refreshFromPull() {
        getFriends()
        
        /*
         Put this when you're done getting whatever you wanted.
         
         if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
         }

         */
    }
    
    func getFriends() {
        
        let userId = UserDefaults.standard.string(forKey: "user_id")
        
        // Send GET request to get friends
        let urlPath = GetRoutes().listFriends + userId!
        
        HelperFunctions().sendGetRequest(urlPath: urlPath) {
            JSON, errorDescription in
            
            // Stop refreshing
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            
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
        friendDetails = [ProfileDetail]()
        
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
                let aboutMe = parser.parseJsonAsString(json: jsonObject as AnyObject, field: "about_me")
                let address = parser.parseJsonAsString(json: jsonObject as AnyObject, field: "address")
                
                // Create new WishDetail
                let newFriendDetail = ProfileDetail(
                    id: id!,
                    fbUserId: fbUserId!,
                    fullName: fullName,
                    username: username!,
                    aboutMe: aboutMe,
                    address: address,
                    profileState: ProfileStates().friendProfile,
                    strangerState: nil,
                    image: nil
                )
                
                friendDetails.append(newFriendDetail)
                
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
            self.navBar.title = "My Friends (\(self.friendDetails.count))"
            self.reloadTable()
        }
    }
    
    // MARK: - Search
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        // Filter friend details
        let search = searchText.lowercased()
        
        searchedFriendDetails = friendDetails.filter{
            $0.username.lowercased().contains(search) ||
            $0.fullName.lowercased().contains(search) ||
            search == ""
        }
        
        // Reload table
        reloadTable()
        
    }
    
    func isSearching() -> Bool {
        return searchController.isActive && searchController.searchBar.text != ""
    }
    
    func getFriendDetails() -> [ProfileDetail] {
        if isSearching() {
            return searchedFriendDetails
        }
        return friendDetails
    }
    
    // MARK: - Table
    func reloadTable() {
        // Ensure that table has been loaded
        if let table = tableView {
            table.estimatedRowHeight = 70
            table.rowHeight = UITableViewAutomaticDimension
            
            table.delegate = self
            table.dataSource = self
            table.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getFriendDetails().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "myFriendCell") as! FriendCell
        
        let row = indexPath.row
        
        let friendDetail = getFriendDetails()[row]
        
        let fbUserId = friendDetail.fbUserId
        HelperFunctions().loadImageFromFacebookWithCompletion(facebookUserId: fbUserId, width: 200, height: 200) { image in
            cell.profileImage.image = image
        }
        
        cell.nameLabel.text = friendDetail.fullName
        cell.usernameLabel.text = friendDetail.username
        
        return cell
    }
    
    
    deinit {
        //remove search controller
        searchController.view!.removeFromSuperview()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "friendToProfile" {
            if let indexPath = tableView.indexPathForSelectedRow {
                
                let profileVC = segue.destination as! ProfileViewController
                profileVC.profileDetail = getFriendDetails()[indexPath.row]
            }
        }
    }
    

}



extension FriendsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
