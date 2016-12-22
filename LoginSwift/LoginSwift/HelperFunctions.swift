//
//  HelperFunctions.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/21/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit

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
    
    
    // Changes the imageView to the image in the URL
    // Usage example: 
    // HelperFunctions().loadImageFromUrl(imageView, imageUrl)
    func loadImageFromUrl(imageView: UIImageView, imageUrl: String) {
        
        // Create Url from string
        let url = NSURL(string: imageUrl)!
        
        // Download task:
        let task = URLSession.shared.dataTask(with: url as URL) { (responseData, responseUrl, error) -> Void in
            
            if error != nil {
                print("ERROR getting image \(error!.localizedDescription)")
            }
            
            // if responseData is not null...
            if let data = responseData{
                
                // execute in UI thread
                DispatchQueue.main.async {
                    imageView.image = UIImage(data: data)
                }
            }
        }
        
        // Run task
        task.resume()
    }
    
    
    func loadImageFromFacebook(imageView: UIImageView, facebookUserId: String, width: Int) {
        let imageUrl = "http://graph.facebook.com/\(facebookUserId)/picture?width=\(width)"
        loadImageFromUrl(imageView: imageView, imageUrl: imageUrl)
    }
    
    
}
