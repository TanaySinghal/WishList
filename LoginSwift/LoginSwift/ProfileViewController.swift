//
//  ProfileViewController.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/21/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit
import Alamofire


// ProfileViewController needs profileState: String and profileDetail: ProfileDetail

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NewWishCellDelegate {
    
    // Input: profileDetail
    var profileDetail: ProfileDetail? {
        didSet {
            getWishes()
        }
    }
    
    @IBOutlet weak var usernameBar: UINavigationItem!
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var aboutMeLabel: UILabel!
    @IBOutlet weak var mailingAddressLabel: UILabel!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var tableView: UITableView!
    
    var isOnPublicList = true
    
    // To make sure we don't load table before view is loaded
    
    //This holds detail about each WishCell
    
    var publicWishDetails = [WishDetail]()
    var privateWishDetails = [WishDetail]()
    
    
    @IBOutlet weak var friendRequestButton: UIButton!
    @IBOutlet weak var sendCancelView: UIView!
    @IBOutlet weak var respondView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // TODO: Show loading message here
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
        
        // Reload table in case it wasn't ready to be reloaded on query
        reloadTable()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Send network query here
    }
    
    
    func getWishes() {
        
        // We have profile Detail
        let userId = profileDetail!.id
        
        var urlPath = GetRoutes().findWish + userId
        
        if isStranger() {
            
            // Only get public wishes
            urlPath = GetRoutes().findPublicWish + userId
            
        }
        
        // Load wishes
        HelperFunctions().sendGetRequest(urlPath: urlPath) {
            JSON, errorDescription in
            
            if let json = JSON {
                self.refreshTableWithJson(JSON: json)
            }
            if let error = errorDescription {
                HelperFunctions().displayAlertMessage(title: "Something went wrong", message: error, viewController: self)
            }
        }
        
    }
    
    func configureView() {
        
        if isStranger() {
            configureStrangerView()
        }
        else {
            showMailingAddres()
            
            if isMe() {
                // Add Settings button
                configureMyView()
            }
            else if isFriend() {
                // Add Unfriend button
                configureFriendView()
            }
        }
        
        
        // Set other UI text
        if let profile = profileDetail {
            usernameBar.title = profile.username
            nameLabel.text = profile.fullName
            aboutMeLabel.text = profile.aboutMe
            mailingAddressLabel.text = profile.address
            
            
            HelperFunctions().loadImageFromFacebookWithCompletion(facebookUserId: profile.fbUserId, width: 360, height: 360) {
                image in
                
                self.profileImage.image = image
            }
        }
        
    }
    
    func configureMyView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(toSettings))
    }
    
    func configureFriendView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unfriend", style: .plain, target: self, action: #selector(unfriend))
    }
    
    func configureStrangerView() {
        
        // Remove right bar button
        navigationItem.rightBarButtonItem = nil
        
        // Hide private wish list button
        if segmentedControl.numberOfSegments > 1 {
            segmentedControl.removeSegment(at: 1, animated: false)
        }
        
        if let strangerState = profileDetail!.strangerState {
            if strangerState == StrangerState().none {
                // Show add button
                showSendCancelView()
                friendRequestButton.setTitle("Send request", for: .normal)
            }
            if strangerState == StrangerState().sentRequest {
                // Show cancel button
                showSendCancelView()
                friendRequestButton.setTitle("Cancel request", for: .normal)
            }
            if strangerState == StrangerState().receivedRequest {
                // Allow add or remove
                showRespondView()
            }
        }
        else {
            print("ERROR: stranger state is nil.")
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Also reloads table
    func refreshTableWithJson(JSON: Any) {
        
        //let profileState = profileDetail?.profileState ?? ""
        
        // First reset both wish lists...
        publicWishDetails = [WishDetail]()
        privateWishDetails = [WishDetail]()
        
        if let jsonArray = JSON as? NSMutableArray {
            
            let parser = JSONParser()
            
            // Append blank wish because our first cell is an add wish cell
            if isMe() {
                publicWishDetails.append(WishDetail(wishId: "", ownerId: "", wish: "", wishDescription: "", isPrivate: false))
                privateWishDetails.append(WishDetail(wishId: "", ownerId: "", wish: "", wishDescription: "", isPrivate: true))
            }
            
            
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
            // There are no wishes. Do nothing since we already reset wishes.
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
    
    
    
    // MARK: - Helper function
    func showMailingAddres() {
        mailingAddressLabel.isHidden = false
        sendCancelView.isHidden = true
        respondView.isHidden = true
    }
    
    func showSendCancelView() {
        mailingAddressLabel.isHidden = true
        sendCancelView.isHidden = false
        respondView.isHidden = true
    }
    
    func showRespondView() {
        mailingAddressLabel.isHidden = true
        sendCancelView.isHidden = true
        respondView.isHidden = false
    }
    
    func getWishList() -> [WishDetail] {
        if isOnPublicList {
            return publicWishDetails
        }
        else {
            return privateWishDetails
        }
    }
    
    func isMe() -> Bool {
      return profileDetail!.profileState == ProfileStates().myProfile
    }
    
    func isFriend() -> Bool {
        return profileDetail!.profileState == ProfileStates().friendProfile
    }
    
    func isStranger() -> Bool {
        return profileDetail!.profileState == ProfileStates().strangerProfile
    }
    
    // MARK: - Table
    func reloadTable() {
            
        if let table = tableView {
            table.estimatedRowHeight = 124
            table.rowHeight = UITableViewAutomaticDimension
            table.delegate = self
            table.dataSource = self
            table.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getWishList().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //var cell = UITableViewCell()
        
        if indexPath.row == 0 && isMe() {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewWishCell") as! NewWishCell
            
            if cell.newWishDelegate == nil {
                cell.newWishDelegate = self
            }
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WishCell") as! WishCell
            
            cell.WishLabel.text = getWishList()[indexPath.row].wish
            return cell
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 && isMe() {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        else {
            self.performSegue(withIdentifier: "wishDetail", sender: self)
        }
    }
    
    
    // All but the first cell can be edited but only if I am the user
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row > 0 && isMe()
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        // If delete is pressed
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            let wishId = getWishList()[indexPath.row].wishId
            let urlPath = GetRoutes().deleteWish + wishId
                
            // Send get request to delete wish. This returns a JSON of the new list of wishes.
            HelperFunctions().sendGetRequest(urlPath: urlPath) {
                JSON, errorDescription in
                
                if let json = JSON {
                    self.refreshTableWithJson(JSON: json)
                }
                if let error = errorDescription {
                    HelperFunctions().displayAlertMessage(title: "Something went wrong", message: error, viewController: self)
                }
            }
            
        }    
    }
    
    // MARK: - Button Functionality
    
    @IBAction func addFriendPressed(_ sender: Any) {
        
        if profileDetail!.strangerState == StrangerState().receivedRequest {
            // Setup to send post request
            let myUserId = UserDefaults.standard.string(forKey: "user_id")
            
            let urlPath = PostRoutes().acceptFriendRequest
            
            let parameters: Parameters = [
                "user_id": myUserId!,
                "sender_id": profileDetail!.id
            ]
            
            // Send post request to accept friend request.
            HelperFunctions().sendPostRequest(urlPath: urlPath, parameters: parameters) {
                JSON, errorDescription in
                
                // Todo: change so that we get new state from server
                if JSON != nil {
                    // Update profile detail
                    var tempProfileDetail = self.profileDetail
                    tempProfileDetail?.strangerState = nil
                    tempProfileDetail?.profileState = ProfileStates().friendProfile
                    self.profileDetail = tempProfileDetail
                    
                    // Reload wishes (private wishes) and UI
                    self.getWishes()
                    self.configureView()
                }
                if let error = errorDescription {
                    HelperFunctions().displayAlertMessage(title: "Something went wrong", message: error, viewController: self)
                }
            }
        }
    }
    
    
    @IBAction func rejectFriendPressed(_ sender: Any) {
        if profileDetail!.strangerState == StrangerState().receivedRequest {
            // Setup to send post request
            let myUserId = UserDefaults.standard.string(forKey: "user_id")
            
            let urlPath = PostRoutes().removeFriendRequest
            
            let parameters: Parameters = [
                "user_id": myUserId!,
                "sender_id": profileDetail!.id
            ]
            
            // Send post request to remove friend request.
            HelperFunctions().sendPostRequest(urlPath: urlPath, parameters: parameters) {
                JSON, errorDescription in
                
                // Todo: change so that we get new state from server
                if JSON != nil {
                    // Update profile detail
                    var tempProfileDetail = self.profileDetail
                    tempProfileDetail?.strangerState = StrangerState().none
                    self.profileDetail = tempProfileDetail
                    
                    // Reload stranger UI (i.e. what buttons we see)
                    self.configureStrangerView()
                }
                if let error = errorDescription {
                    HelperFunctions().displayAlertMessage(title: "Something went wrong", message: error, viewController: self)
                }
            }
            
        }
    }
    
    
    // Send or remove friend request
    @IBAction func friendRequestPressed(_ sender: Any) {
        
        let strangerState = profileDetail!.strangerState
        // Do something here
        if strangerState == nil || strangerState == StrangerState().receivedRequest {
            print("ERROR while sending/removing friend request. Wrong stranger state: \(strangerState)")
            return
        }
        
        // Create JSON
        let myUserId = UserDefaults.standard.string(forKey: "user_id")
        let friendId = profileDetail!.id
        
        
        var sending: Bool = true
        var urlPath = PostRoutes().sendFriendRequest
        
        if strangerState == StrangerState().sentRequest {
            sending = false
            urlPath = PostRoutes().removeFriendRequest
        }
        
        let parameters: Parameters = [
            "sender_id": myUserId!,
            "user_id": friendId
        ]
        
        HelperFunctions().sendPostRequest(urlPath: urlPath, parameters: parameters) {
            JSON, errorDescription in
            
            if JSON != nil {
                
                var tempProfileDetail = self.profileDetail
                
                // If sending, change stranger state to sent request
                if sending {
                    tempProfileDetail?.strangerState = StrangerState().sentRequest
                }
                    // If removing, change stranger state to none
                else {
                    tempProfileDetail?.strangerState = StrangerState().none
                }
                // Update profile detail
                self.profileDetail = tempProfileDetail
                
                // Reload stranger UI (i.e. what buttons we see)
                self.configureStrangerView()
            }
            if let error = errorDescription {
                HelperFunctions().displayAlertMessage(title: "Something went wrong", message: error, viewController: self)
            }
        }
        
        
        // If not, then send request, and update (add to) friend requests and do configureView()
    }
    
    // Add wish button pressed
    func newWishAdded(cell: NewWishCell, wish: String, wishDescription: String) {
        
        // Create JSON
        let parameters: Parameters = [
            "owner": profileDetail!.id,
            // TODO: Make sure not empty
            "text": cell.wishField.text!,
            "description": cell.wishDescriptionField.text ?? "",
            // Return opposite of isOnPublicList
            "is_private": isOnPublicList != true
        ]
        
        let urlPath = PostRoutes().createWish
        
        // Send post request to create wish to database. This returns a JSON with a new list of wishes.
        HelperFunctions().sendPostRequest(urlPath: urlPath, parameters: parameters) {
            JSON, errorDescription in
            
            if let json = JSON {
                
                // Clear fields
                cell.wishDescriptionField.text = ""
                cell.wishField.text = ""
                
                // Reset table with new data
                self.refreshTableWithJson(JSON: json)
            }
            if let error = errorDescription {
                HelperFunctions().displayAlertMessage(title: "Something went wrong", message: error, viewController: self)
            }
        }
        
    }
    
    
    func unfriend() {
        print("Unfriending \(profileDetail!.fullName) ...")
        
        let myUserId = UserDefaults.standard.string(forKey: "user_id")
        
        // If remove friend
        // Create JSON
        let parameters: Parameters = [
            "user_id": myUserId!,
            "friend_id": profileDetail!.id
        ]
        
        let urlPath = PostRoutes().removeFriend
        
        HelperFunctions().sendPostRequest(urlPath: urlPath, parameters: parameters) {
            JSON, errorDescription in
            
            if JSON != nil {
                
                // Change profileState to stranger
                var tempProfileDetail = self.profileDetail
                tempProfileDetail?.profileState = ProfileStates().strangerProfile
                tempProfileDetail?.strangerState = StrangerState().none
                self.profileDetail = tempProfileDetail
                
                // Empty public wishes
                self.publicWishDetails.removeAll()
                
                // TODO: Unwind to FriendsVC should remove friend from list
                
                // Refresh UI
                self.configureView()
            }
            if let error = errorDescription {
                HelperFunctions().displayAlertMessage(title: "Something went wrong", message: error, viewController: self)
            }
        }
    }
    
    
    // MARK: - Navigation
    func toSettings() {
        self.performSegue(withIdentifier: "settingsSegue", sender: self)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "wishDetail" {
            
            if let indexPath = tableView.indexPathForSelectedRow {
                let destination = segue.destination as! WishDetailViewController
                destination.wishDetail = getWishList()[indexPath.row]
            }
        }
    }
    
}
