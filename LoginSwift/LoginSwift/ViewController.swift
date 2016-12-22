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

// Alamofire tutorial: http://www.appcoda.com/alamofire-beginner-guide/
// Alamofire github: https://github.com/Alamofire/Alamofire/blob/master/Documentation/Alamofire%204.0%20Migration%20Guide.md

class ViewController: UIViewController, LoginButtonDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        print("Hello from VC")
        if let accessToken = FacebookCore.AccessToken.current {
            // User is logged in, use 'accessToken' here.
            print("Already logged in??!!")
            print("User id is \(accessToken.userId)")
        }
        else {
            print("VC: Not logged in already...")
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
            print("Facebook login failed (\(error))")
        case .success(_, _, let accessToken):
            print("Facebook login succeeded! My user ID is: \(accessToken.userId!)")
            
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
                    
                    Alamofire.request("http://localhost:8080/user/authorize_from_fb", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                        
                        switch response.result {
                        case .success(let value):
                            
                            if let JSON = response.result.value {
                                print("User JSON:\n \(JSON)")
                                
                                
                                // Parse JSON so we get some values...
                                // We already have all the other values...
                                let parser = JSONParser()
                                let user_id = parser.parseJsonAsString(json: JSON as AnyObject, field: "_id")
                                let username = parser.parseJsonAsString(json: JSON as AnyObject, field: "username")
                                
                                // Save this data locally
                                let userSession = UserDefaults.standard
                                userSession.set(user_id, forKey: "user_id")
                                userSession.set(fb_user_id, forKey: "fb_user_id")
                                userSession.set(first_name, forKey: "first_name")
                                userSession.set(last_name, forKey: "last_name")
                                userSession.set(email, forKey: "email")
                                userSession.set(username, forKey: "username")
                                
                                // How to retrieve
                                //print("Username: \(userSession.string(forKey: "username")!)")
                                
                                if username!.characters.count > 16 {
                                    //Go to one more step
                                    
                                    let about_me = parser.parseJsonAsString(json: JSON as AnyObject, field: "about_me")
                                    let address = parser.parseJsonAsString(json: JSON as AnyObject, field: "address")
                                    userSession.set(about_me, forKey: "about_me")
                                    userSession.set(address, forKey: "address")
                                    
                                    self.performSegue(withIdentifier: "oneMoreStep", sender: self)
                                }
                                else {
                                    // Go directly to profile
                                    self.performSegue(withIdentifier: "loginSegue", sender: self)
                                }
                                
                            }
                                
                            else {
                                print("ERROR occured in VC while posting. Perhaps a problem with serializing JSON. Here is the response we got: \(value)")
                            }
                            
                        // Handle failure
                        case .failure(let error):
                            print("Post request from VC failed: \(error)")
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
    
}

