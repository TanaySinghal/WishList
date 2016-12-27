//
//  FriendRequestCell.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/22/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit


protocol FriendRequestCellDelegate {
    func modifyFriendRequest(urlPath: String, cell: FriendRequestCell)
}

// accept or remove

class FriendRequestCell: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    var senderId: String?
    
    var friendRequestDelegate: FriendRequestCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func acceptRequest(_ sender: Any) {
        if let delegate = friendRequestDelegate {
            delegate.modifyFriendRequest(urlPath: PostRoutes().acceptFriendRequest, cell: self)
        }
    }
    
    
    @IBAction func removeRequest(_ sender: Any) {
        if let delegate = friendRequestDelegate {
            delegate.modifyFriendRequest(urlPath: PostRoutes().removeFriendRequest, cell: self)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
