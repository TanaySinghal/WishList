//
//  HelperFunctions.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/21/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit
import Alamofire

class HelperFunctions {
    
    func generateRandomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    
    // This shows message and dismisses on "OK"
    func displayAlertMessage(title:String, message:String, viewController:AnyObject) {
        let myAlert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        
        let okAction = UIAlertAction(title:"OK", style: .default, handler: nil);
        
        myAlert.addAction(okAction);
        viewController.present(myAlert, animated: true, completion:nil);
    }
    
    
    //This allows any action on OK or Cancel
    func displayConfirmMessage(title: String, message: String, viewController: AnyObject, completionHandler: @escaping(Bool) -> Void) {
        let myAlert = UIAlertController(title: title, message: message, preferredStyle: .alert);
        
        
        let continueButton = UIAlertAction(title: "Continue", style: .default) {
            //Move to next page
            action in

            completionHandler(true)
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .default) {
            action in
            
            completionHandler(false)
        }
        
        myAlert.addAction(continueButton);
        myAlert.addAction(cancelButton);
        viewController.present(myAlert, animated: true, completion: nil);
    }
    
    
    // MARK - Networking
    func loadImageFromUrlWithCompletion(imageUrl: String, completionHandler: @escaping (UIImage?) -> Void) {
        
        // Create Url from string
        let url = NSURL(string: imageUrl)!
        
        // Download task:
        let task = URLSession.shared.dataTask(with: url as URL) { (responseData, responseUrl, error) -> Void in
            
            if error != nil {
                print("ERROR getting image \(error!.localizedDescription)")
                completionHandler(nil)
            }
            
            if let data = responseData{
                
                // execute in UI thread
                DispatchQueue.main.async {
                    completionHandler(UIImage(data: data))
                }
            }
        }
        
        // Run task
        task.resume()
        
    }
    
    /* Usage:
    HelperFunctions().loadImageFromFacebookWithCompletion(facebookUserId: fbUserId, width: 200, height: 200) { image in
    
     // Do something with image
     // Example:
     // profileImage.image = image
    }*/
    
    func loadImageFromFacebookWithCompletion(facebookUserId: String, width: Int, height: Int, completionHandler:@escaping (UIImage?) -> Void) {
        
        // Create Url from string
        let imageUrl = "http://graph.facebook.com/\(facebookUserId)/picture?width=\(width)&height=\(height)"
        //let url = NSURL(string: imageUrl)!
        
        loadImageFromUrlWithCompletion(imageUrl: imageUrl) { image in
                // Do something
            completionHandler(image)
        }
    }
    
    
    // Example urlPath: "/wish/remove_friend_request"
    func sendGetRequest(urlPath: String, completionHandler:@escaping (Any?, String?) -> Void) {
        
        // Send post request to accept friend request.
        Alamofire.request(hostUrl + urlPath).responseJSON { response in
            
            switch response.result {
            case .success(let value):
                if let JSON = response.result.value {
                    // Send completion handler
                    completionHandler(JSON, nil)
                }
                else {
                    print("Failed to serialize JSON. Here is the result: \(value)")
                    completionHandler(nil, nil)
                }
                
            case .failure(let error):
                completionHandler(nil, error.localizedDescription)
            }
        }
    }
    
    // Example urlPath: "/wish/remove_friend_request"
    func sendPostRequest(urlPath: String, parameters: Parameters, completionHandler:@escaping (Any?, String?) -> Void) {
        
        // Send post request to accept friend request.
        Alamofire.request(hostUrl + urlPath, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            
            switch response.result {
            case .success(let value):
                if let JSON = response.result.value {
                    // Send completion handler
                    completionHandler(JSON, nil)
                }
                else {
                    print("Failed to serialize JSON. Here is the result: \(value)")
                    completionHandler(nil, nil)
                }
                
            case .failure(let error):
                completionHandler(nil, error.localizedDescription)
            }
        }
    }

}
