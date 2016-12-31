//
//  GlobalVariables.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/25/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit
import Foundation

// MARK: - Constants
let hostUrl = "http://localhost:8080"

// MARK: - States
struct ProfileStates {
    let myProfile = "myProfile"
    let friendProfile = "friendProfile"
    let strangerProfile = "strangerProfile"
}

struct StrangerState {
    let receivedRequest = "received"
    let sentRequest = "sent"
    let none = "none"
}

// MARK: - Details
struct ProfileDetail {
    var id: String
    var fbUserId: String
    var fullName: String
    var username: String
    
    // New - about me, address, profileState
    var aboutMe: String?
    var address: String?
    var profileState: String
    var strangerState: String?
    
    var image: UIImage?
}

struct WishDetail {
    var wishId: String
    var ownerId: String
    var wish: String
    var wishDescription: String
    var isPrivate: Bool
}

// MARK: - Networking
struct GetRoutes {
    let removeUser = "/user/remove/" // + userId
    
    let listFriendRequests = "/user/list_friend_requests/" // + userId
    let listFriends = "/user/list_friends/" // + userId
    
    let findWish = "/wish/find_wish_by_user/" // + userId
    let findPublicWish = "/wish/find_public_wish_by_user/" // + userId
    let deleteWish = "/wish/delete/" // + wishId
}

struct PostRoutes {
    let createWish = "/wish/create/"
    
    let updateUser = "/user/update/"
    
    let authorizeFromFb = "/user/authorize_from_fb/"
    
    let acceptFriendRequest = "/user/accept_friend_request/"
    let removeFriendRequest = "/user/remove_friend_request/"
    let sendFriendRequest = "/user/send_friend_request/"
    
    let removeFriend = "/user/remove_friend/"
    
}

// MARK: - Extensions
extension NSRange {
    func range(for str: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }
        
        guard let fromUTFIndex = str.utf16.index(str.utf16.startIndex, offsetBy: location, limitedBy: str.utf16.endIndex) else { return nil }
        guard let toUTFIndex = str.utf16.index(fromUTFIndex, offsetBy: length, limitedBy: str.utf16.endIndex) else { return nil }
        guard let fromIndex = String.Index(fromUTFIndex, within: str) else { return nil }
        guard let toIndex = String.Index(toUTFIndex, within: str) else { return nil }
        
        return fromIndex ..< toIndex
    }
}
