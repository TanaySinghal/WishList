//
//  FriendRequestsViewController.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/22/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit
import Alamofire


class FriendRequestsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FriendRequestCellDelegate {

    @IBOutlet weak var navBar: UINavigationItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    var requestSenders = [ProfileDetail]()
    
    var firstTimeLoad = true
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add refresh control
        refreshControl.addTarget(self, action: #selector(refreshFromPull), for: .valueChanged)
        
        getFriendRequests()
    }

    // Get updated friend request list whenever view appears
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add refresh controller
        self.tableView.addSubview(refreshControl)
        
        if firstTimeLoad {
            firstTimeLoad = false
            reloadTable()
        }
        else {
            getFriendRequests()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func refreshFromPull() {
        getFriendRequests()
        
        /*
         If copied and pasted, put this when you're done getting whatever you wanted.
         
         if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
         }
         
         */
    }
    
    func getFriendRequests() {
        // Do any additional setup after loading the view.
        let userId = UserDefaults.standard.string(forKey: "user_id")
        
        // Send GET request to find friend requests
        let urlPath = GetRoutes().listFriendRequests + userId!
        
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
                HelperFunctions().displayAlertMessage(title: "Something went wrong", message: error, viewController: self)
            }
            
        }
        
    }
    
    // Also reloads table
    func refreshTableWithJson(JSON: Any) {
        
        // First reset requestSenders
        requestSenders = [ProfileDetail]()
        
        // Next go through array
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
                let newRequestSender = ProfileDetail(
                    id: id!,
                    fbUserId: fbUserId!,
                    fullName: fullName,
                    username: username!,
                    aboutMe: nil,
                    address: nil,
                    profileState: ProfileStates().strangerProfile,
                    strangerState: StrangerState().receivedRequest,
                    image: nil
                )
                
                
                requestSenders.append(newRequestSender)
                
            }
        }
        else if JSONSerialization.isValidJSONObject(JSON) {
            // There are no friend requests..
        }
        else {
            print("FriendRequestVC: JSON is not valid. Here is the JSON: \(JSON)")
        }
        
        
        // Reload table to see change
        DispatchQueue.main.async{
            self.navBar.title = "Friend Requests (\(self.requestSenders.count))"
            self.reloadTable()
        }
    }
    
    
    // MARK: - FriendRequestCellDelegate
    func modifyFriendRequest(urlPath: String, cell: FriendRequestCell) {
        
        let userId = UserDefaults.standard.string(forKey: "user_id")
        
        // Create JSON
        let parameters: Parameters = [
            "sender_id": cell.senderId!,
            // TODO: Make sure not empty
            "user_id": userId!
        ]
        
        // Send post request to accept friend request. 
        // This returns a JSON with a new list of friend requests, after removing this one.
        
        HelperFunctions().sendPostRequest(urlPath: urlPath, parameters: parameters) {
            JSON, errorDescription in
            
            if let json = JSON {
                
                // Reset table with new data
                self.refreshTableWithJson(JSON: json)
            }
            if let error = errorDescription {
                HelperFunctions().displayAlertMessage(title: "Something went wrong", message: error, viewController: self)
            }
        }
    }
    
    
    // MARK: - Table
    func reloadTable() {

        if let table = tableView {
            table.estimatedRowHeight = 102
            table.rowHeight = UITableViewAutomaticDimension
            
            table.delegate = self
            table.dataSource = self
            table.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestSenders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendRequestCell") as! FriendRequestCell
        let row = indexPath.row
        
        let fbUserId = requestSenders[row].fbUserId
        
        HelperFunctions().loadImageFromFacebookWithCompletion(facebookUserId: fbUserId, width: 200, height: 200) { image in
            cell.profileImage.image = image
        }
        
        cell.senderId = requestSenders[row].id
        cell.fullNameLabel.text = requestSenders[row].fullName
        cell.usernameLabel.text = requestSenders[row].username
        
        if cell.friendRequestDelegate == nil {
            cell.friendRequestDelegate = self
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Do nothing... segue is handled from story board
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "friendRequestToProfile" {
            
            if let indexPath = tableView.indexPathForSelectedRow {
                
                let profileVC = segue.destination as! ProfileViewController
                
                profileVC.profileDetail = requestSenders[indexPath.row]
                
            }
            
        }
    }
    

}
