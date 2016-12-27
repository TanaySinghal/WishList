//
//  ViewController.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/21/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import Alamofire

// Check this out: https://github.com/StabbyMcDuck/crapper_keeper_ios/blob/d9db8f5833fd91bcbbd14a189ed921e303b05ff5/crapper_keeper_ios/LoginViewController.swift

// Check this out for graph: https://github.com/jestapinski/FinalBlockTrader442/blob/c23d17d0ea268b2f8cc727fe300b907558ed064b/BlockTrader/MainPageViewController.swift


class ViewController: UIViewController, LoginButtonDelegate {

    var myProfileDetail: ProfileDetail?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let accessToken = FacebookCore.AccessToken.current {
            // User is logged in, use 'accessToken' here.
            print("Already logged in??!!")
            print("User id is \(accessToken.userId)")
        }
        else {
            let loginButton = LoginButton(readPermissions: [ .publicProfile, .email, .userFriends])
            
            loginButton.center = view.center
            loginButton.delegate = self
            view.addSubview(loginButton)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        print ("Hello from login complete")
        switch result {
        case .cancelled:
            print("Facebook login cancelled")
        case .failed(let error):
            print("Facebook login failed: (\(error.localizedDescription))")
        case .success(_, _, let accessToken):
            print("Facebook login succeeded! My user ID is: \(accessToken.userId!)")
            
            // Hide log out button
            loginButton.isHidden = true
            
            // Send graph request
            let connection = GraphRequestConnection()
            let params = ["fields" : "email, name, id"]
            
            connection.add(GraphRequest(graphPath: "/me", parameters: params)) { httpResponse, result in
                switch result {
                case .success(let response):
                    //print("Graph Request Succeeded. \(response.dictionaryValue!["name"]!)'s email is \(response.dictionaryValue!["email"]!)")
                    
                    let name: String = response.dictionaryValue!["name"]! as! String
                    
                    let fb_user_id: String = response.dictionaryValue!["id"]! as! String
                    let first_name: String = name.components(separatedBy: " ").first!
                    let last_name: String = name.components(separatedBy: " ").last!
                    let email: String = response.dictionaryValue!["email"]! as! String
                    // Make them choose a username.. for now let's just create one
                    let username = "temp_user_" + HelperFunctions().generateRandomString(length: 10)
                    
                    
                    // Send post request
                    let parameters: Parameters = [
                        "fb_user_id": fb_user_id,
                        "first_name": first_name,
                        "last_name": last_name,
                        "username": username,
                        "email": email,
                    ]
                    
                    let urlPath = PostRoutes().authorizeFromFb
                    
                    HelperFunctions().sendPostRequest(urlPath: urlPath, parameters: parameters) {
                        JSON, errorDescription in
                        
                        if let json = JSON {
                            
                            // Parse JSON
                            let parser = JSONParser()
                            
                            // Get information from database (not from FB)
                            let user_id = parser.parseJsonAsString(json: json as AnyObject, field: "_id")
                            let username = parser.parseJsonAsString(json: json as AnyObject, field: "username")
                            let about_me = parser.parseJsonAsString(json: json as AnyObject, field: "about_me")
                            let address = parser.parseJsonAsString(json: json as AnyObject, field: "address")
                            
                            
                            self.myProfileDetail = ProfileDetail(
                                id: user_id!,
                                fbUserId: fb_user_id,
                                fullName: first_name + " " + last_name,
                                username: username!,
                                aboutMe: about_me,
                                address: address,
                                profileState: ProfileStates().myProfile,
                                strangerState: nil,
                                image: nil
                            )
                            
                            // Save ID locally
                            UserDefaults.standard.set(user_id, forKey: "user_id")
                            
                            if username!.characters.count > 16 {
                                //Go to one more step
                                self.performSegue(withIdentifier: "oneMoreStep", sender: self)
                            }
                            else {
                                // Go directly to profile
                                self.performSegue(withIdentifier: "loginSegue", sender: self)
                            }
                            
                        }
                        else if let error = errorDescription {
                            print("ERROR: \(error)")
                            
                            // Display alert message
                            HelperFunctions().displayAlertMessage(title: "Login failed", message: "We could not connect to our servers. Please check your internet connection. Otherwise, maybe our servers are down. Sorry!", viewController: self)
                            
                            // Log me out
                            let loginManager = LoginManager()
                            loginManager.logOut()
                            
                            loginButton.isHidden = false
                        }
                        else {
                            print("No error but no JSON either")
                        }
                    }
                    
                case .failed(let error):
                    print("Graph Request Failed: \(error)")
                }
            }
            connection.start()
            
        }
    }
    
    // A different screen is used for logout
    func loginButtonDidLogOut(_ loginButton: LoginButton) {}
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "loginSegue" {
            
            let tabBarController = segue.destination as! UITabBarController
            let destNavController = tabBarController.viewControllers?.last as! UINavigationController
            
            let profileVC = destNavController.topViewController as! ProfileViewController
            
            profileVC.profileDetail = myProfileDetail
            
        }
        
        if segue.identifier == "oneMoreStep" {
            
            let viewController = segue.destination as! OneMoreStepViewController
            viewController.profileDetail = myProfileDetail
        }
        
    }
    
}

