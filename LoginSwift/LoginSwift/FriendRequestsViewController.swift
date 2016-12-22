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

    @IBOutlet weak var tableView: UITableView!
    
    struct RequestSender {
        var id: String
        var fbUserId: String
        var fullName: String
        var username: String
    }
    
    var requestSenders = [RequestSender]()
    
    var userId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        userId = UserDefaults.standard.string(forKey: "user_id")
        
        // Send GET request to find friend requests
        Alamofire.request("http://localhost:8080/user/list_friend_requests/" + userId!).responseJSON { response in
            // New code
            switch response.result {
            case .success(let value):
                if let JSON = response.result.value {
                    self.refreshTableWithJson(JSON: JSON)
                }
                else {
                    print("Failed to serialize JSON in FriendRequestVC. Here is the result: \(value)")
                }
                
            case .failure(let error):
                print("Get request from FriendRequestVC failed: \(error)")
            }
        }
        
    }

    override func viewDidAppear(_ animated: Bool) {
        
        tableView.estimatedRowHeight = 124
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // Also reloads table
    func refreshTableWithJson(JSON: Any) {
        
        // First reset requestSenders
        requestSenders = [RequestSender]()
        
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
                let newRequestSender = RequestSender(
                    id: id!,
                    fbUserId: fbUserId!,
                    fullName: fullName,
                    username: username!
                )
                
                requestSenders.append(newRequestSender)
                
            }
        }
        else if JSONSerialization.isValidJSONObject(JSON) {
            print("There are no friend requests")
        }
        else {
            print("FriendRequestVC: JSON is not valid. Here is the JSON: \(JSON)")
        }
        
        
        // Reload table to see change
        DispatchQueue.main.async{
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.reloadData()
        }
    }
    
    
    // MARK: - FriendRequestCellDelegate
    func modifyFriendRequest(action: String, cell: FriendRequestCell) {
        
        // Create JSON
        let parameters: Parameters = [
            "sender_id": cell.senderId!,
            // TODO: Make sure not empty
            "user_id": userId!
        ]
        
        // Send post request to accept friend request. This returns a JSON with a new list of friend requests, after removing this one.
        Alamofire.request("http://localhost:8080/user/\(action)_friend_request", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            switch response.result {
            case .success(let value):
                
                if let JSON = response.result.value {
                    
                    // Reset table with new data
                    self.refreshTableWithJson(JSON: JSON)
                    
                }
                else {
                    print("Failed to serialize JSON in FriendRequestVC. Here is the result: \(value)")
                }
                
            case .failure(let error):
                print("Post request from FriendRequestVC failed: \(error)")
            }
        }
    }
    
    
    // MARK: - Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requestSenders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "friendRequestCell") as! FriendRequestCell
        let row = indexPath.row
        
        let fbUserId = requestSenders[row].fbUserId
        //cell.profileImage.image = HelperFunctions().loadImageFromFacebook(facebookUserId: fbUserId, width: 360)
        HelperFunctions().loadImageFromFacebook(imageView: cell.profileImage, facebookUserId: fbUserId, width: 360)
        cell.fullNameLabel.text = requestSenders[row].fullName
        cell.usernameLabel.text = requestSenders[row].username
        
        if cell.friendRequestDelegate == nil {
            cell.friendRequestDelegate = self
        }
        
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
