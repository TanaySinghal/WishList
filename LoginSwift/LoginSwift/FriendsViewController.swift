//
//  FriendsViewController.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/22/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit
import Alamofire

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var navBar: UINavigationItem!
    
    struct FriendDetail {
        var id: String
        var fbUserId: String
        var fullName: String
        var username: String
    }
    
    var friendDetails = [FriendDetail]()
    
    var userId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        userId = UserDefaults.standard.string(forKey: "user_id")
        
        // Send GET request to find friend requests
        Alamofire.request("http://localhost:8080/user/list_friends/" + userId!).responseJSON { response in
            // New code
            switch response.result {
            case .success(let value):
                if let JSON = response.result.value {
                    self.refreshTableWithJson(JSON: JSON)
                }
                else {
                    print("Failed to serialize JSON in FriendsVC. Here is the result: \(value)")
                }
                
            case .failure(let error):
                print("Get request from FriendsVC failed: \(error)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewDidAppear(_ animated: Bool) {
        //reloadTable()
    }
    
    
    
    func refreshTableWithJson(JSON: Any) {
        
        // Reset friendDetails
        friendDetails = [FriendDetail]()
        
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
                let newFriendDetail = FriendDetail(
                    id: id!,
                    fbUserId: fbUserId!,
                    fullName: fullName,
                    username: username!
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
    
    
    // MARK: - Table
    func reloadTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendDetails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "myFriendCell") as! FriendCell
        
        let row = indexPath.row
        
        let fbUserId = friendDetails[row].fbUserId
        HelperFunctions().loadImageFromFacebook(imageView: cell.profileImage, facebookUserId: fbUserId, width: 200, height: 200)
        cell.nameLabel.text = friendDetails[row].fullName
        cell.usernameLabel.text = friendDetails[row].username
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
