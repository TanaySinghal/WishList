//
//  ProfileViewController.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/21/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit
import Alamofire

class ProfileStates {
    let myProfile = "myProfile"
    let friendProfile = "friendProfile"
    let strangerProfile = "strangerProfile"
}

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NewWishCellDelegate {

    
    @IBOutlet weak var usernameBar: UINavigationItem!
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var aboutMeLabel: UILabel!
    @IBOutlet weak var mailingAddressLabel: UILabel!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var tableView: UITableView!
    
    var isOnPublicList = true
    
    //This holds detail about each WishCell
    struct WishDetail {
        var wishId: String
        var ownerId: String
        var wish: String
        var wishDescription: String
        var isPrivate: Bool
    }
    
    var publicWishDetails = [WishDetail]()
    var privateWishDetails = [WishDetail]()
    
    var userId: String?
    
    //States: me, friend, stranger
    var profileState: String = ProfileStates().myProfile
    
    @IBOutlet weak var strangerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // TODO: Change this button depending on my profile, friend profile, or stranger's profile
        // Add Settings button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(toSettings))
        
        
        // Get wishes of this user
        // TODO: If not my profile, then get from server... store JSON
        userId = UserDefaults.standard.string(forKey: "user_id")
        
        // TODO: If state is stranger, change URL to find_public_wish_by_user (for security)
        // Send get request to database
        Alamofire.request("http://localhost:8080/wish/find_wish_by_user/" + userId!).responseJSON { response in
            // New code
            switch response.result {
            case .success(let value):
                if let JSON = response.result.value {
                    self.refreshTableWithJson(JSON: JSON)
                }
                else {
                    print("Failed to serialize JSON in ProfileVC. Here is the result: \(value)")
                }
                
            case .failure(let error):
                print("Get request from ProfileVC failed: \(error)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if profileState == ProfileStates().strangerProfile {
            // Hide mailing address
            mailingAddressLabel.isHidden = true
            strangerView.isHidden = false
            
            // Hide private wish list button
            if segmentedControl.numberOfSegments > 1 {
                segmentedControl.removeSegment(at: 1, animated: false)
            }
        }
        else {
            mailingAddressLabel.isHidden = false
            strangerView.isHidden = true
        }
        
        // TODO: If my profile, get data from user defaults.
                // Else, get data from server. Exclude address if stranger.
        // Get data from UserDefaults
        if profileState == ProfileStates().myProfile {
            let userSession = UserDefaults.standard
            let fbUserId = userSession.string(forKey: "fb_user_id") ?? ""
            let username = userSession.string(forKey: "username") ?? ""
            let firstName = userSession.string(forKey: "first_name") ?? ""
            let lastName = userSession.string(forKey: "last_name") ?? ""
            let fullName = firstName + " " + lastName
            let aboutMe = userSession.string(forKey: "about_me") ?? ""
            let address = userSession.string(forKey: "address") ?? ""
            
            usernameBar.title = username
            nameLabel.text = fullName
            aboutMeLabel.text = aboutMe
            // TODO: If not friends, hide mailing address, and show button
            mailingAddressLabel.text = address 
            
            
            HelperFunctions().loadImageFromFacebookWithCompletion(facebookUserId: fbUserId, width: 360, height: 360) { image in
                self.profileImage.image = image
            }
            
        }
        
        reloadTable()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Also reloads table
    func refreshTableWithJson(JSON: Any) {
        
        // First reset both wish lists...
        publicWishDetails = [WishDetail]()
        privateWishDetails = [WishDetail]()
        
        if let jsonArray = JSON as? NSMutableArray {
            
            let parser = JSONParser()
            
            // TODO: Do the next two lines only if I am the user
            // Append blank cell to both publicWishDetails and privateWishDetails because our first cell is an add cell
            publicWishDetails.append(WishDetail(wishId: "", ownerId: "", wish: "", wishDescription: "", isPrivate: false))
            privateWishDetails.append(WishDetail(wishId: "", ownerId: "", wish: "", wishDescription: "", isPrivate: true))
            
            
            for jsonObject in jsonArray {
                
                // Extract information
                let wishId = parser.parseJsonAsString(json: jsonObject as AnyObject, field: "_id")
                let ownerId = parser.parseJsonAsString(json: jsonObject as AnyObject, field: "owner")
                let wish = parser.parseJsonAsString(json: jsonObject as AnyObject, field: "text")
                let wishDescription = parser.parseJsonAsString(json: jsonObject as AnyObject, field: "description") ?? ""
                let isPrivate = parser.parseJsonAsBool(json: jsonObject as AnyObject, field: "is_private")
                
                // Create new WishDetail
                let newWishDetail = WishDetail(
                    wishId: wishId!,
                    ownerId: ownerId!,
                    wish: wish!,
                    wishDescription: wishDescription,
                    isPrivate: isPrivate!
                )
                
                // Append newWishDetail to either public or private wish list
                if isPrivate! {
                    privateWishDetails.append(newWishDetail)
                }
                else {
                    publicWishDetails.append(newWishDetail)
                }
                
            }
        }
        else if JSONSerialization.isValidJSONObject(JSON) {
            print("There are no wishes")
        }
        else {
            print("ProfileVC: JSON is not valid. Here is the JSON: \(JSON)")
        }
        
        // Reload table to see change
        DispatchQueue.main.async {
            self.reloadTable()
        }
    }

    
    // MARK: - Segmented Control
    @IBAction func onTabChange(_ sender: Any) {
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            isOnPublicList = true
            tableView.reloadData()
            break;
        case 1:
            isOnPublicList = false
            tableView.reloadData()
            break;
        default:
            print("Error! No tabs selected")
            break;
        }
        
    }
    
    func getWishList() -> [WishDetail] {
        if isOnPublicList {
            return publicWishDetails
        }
        else {
            return privateWishDetails
        }
    }
    
    
    // MARK: - Table
    func reloadTable() {
        tableView.estimatedRowHeight = 124
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getWishList().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //var cell = UITableViewCell()
        
        let row = indexPath.row
        // TODO: if row == 0 and state = "me"
        if row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewWishCell") as! NewWishCell
            
            if cell.newWishDelegate == nil {
                cell.newWishDelegate = self
            }
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WishCell") as! WishCell
            // TODO: Add if statement to make this work for private wish
            cell.WishLabel.text = getWishList()[row].wish
            return cell
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // All but the first cell can be deleted
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row > 0
    }
    
    //https://www.andrewcbancroft.com/2015/07/16/uitableview-swipe-to-delete-workflow-in-swift/
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            // TODO: Check if we are public or private, depending on button
            let wishId = getWishList()[indexPath.row].wishId
            
            // Send get request to delete wish. This returns a JSON of the new list of wishes.
            Alamofire.request("http://localhost:8080/wish/delete/" + wishId).responseJSON { response in
                // New code
                switch response.result {
                case .success(let value):
                    if let JSON = response.result.value {
                        // Update arrays and refresh table
                        self.refreshTableWithJson(JSON: JSON)
                    }
                    else {
                        print("Failed to serialize JSON in ProfileVC. Here is the result: \(value)")
                    }
                    
                case .failure(let error):
                    print("Get request from ProfileVC failed: \(error)")
                }
            }
            
        }    
    }
    
    // Add wish button pressed
    func newWishAdded(cell: NewWishCell, wish: String, wishDescription: String) {
        
        // Create JSON
        let parameters: Parameters = [
            "owner": userId!,
            // TODO: Make sure not empty
            "text": cell.wishField.text!,
            "description": cell.wishDescriptionField.text ?? "",
            // Return opposite of isOnPublicList
            "is_private": isOnPublicList != true
        ]
        
        // Send post request to create wish to database. This returns a JSON with a new list of wishes.
        Alamofire.request("http://localhost:8080/wish/create", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            switch response.result {
            case .success(let value):
                
                if let JSON = response.result.value {
                    
                    // Clear fields
                    cell.wishDescriptionField.text = ""
                    cell.wishField.text = ""
                    
                    // Reset table with new data
                    self.refreshTableWithJson(JSON: JSON)
                    
                }
                else {
                    print("Failed to serialize JSON in ProfileVC. Here is the result: \(value)")
                }
                
            case .failure(let error):
                print("Post request from ProfileVC failed: \(error)")
            }
        }
        
    }
    
    // MARK: - Navigation
    func toSettings() {
        self.performSegue(withIdentifier: "settingsSegue", sender: self)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    /*override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
    }*/
    
}
