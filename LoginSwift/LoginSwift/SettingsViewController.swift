//
//  SettingsViewController.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/21/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import Alamofire

class SettingsViewController: UIViewController, LoginButtonDelegate {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let accessToken = FacebookCore.AccessToken.current {
            // User is logged in, use 'accessToken' here.
            print("Settings VC: User is logged in.")
            print("User id is \(accessToken.userId)")
        }
        else {
            print("Settings VC: User is not logged in... something went wrong...")
        }
        
        let loginButton = LoginButton(readPermissions: [ .publicProfile, .email, .userFriends])
        loginButton.center = view.center
        loginButton.delegate = self
        
        view.addSubview(loginButton)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Login is handled in ViewController
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {}
    
    // A different screen is used for logout
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        print("Log out button pressed")
        
        // Remove log in button
        loginButton.isHidden = true
        
        //Do segue "logOutSegue"
        self.performSegue(withIdentifier: "logoutSegue", sender: self)
    }
}
