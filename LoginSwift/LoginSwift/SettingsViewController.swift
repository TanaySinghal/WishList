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

class SettingsViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    
    @IBOutlet weak var aboutMeField: UITextView!
    @IBOutlet weak var mailingAddressField: UITextView!
    
    
    var profileDetail: ProfileDetail?
    
    let maxTextViewLength = 150
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Make text views look like text fields
        let borderColor = UIColor(red: 215.0/255.0, green: 215.0/255.0, blue: 215.0/255.0, alpha: 1)
        
        aboutMeField.layer.borderColor = borderColor.cgColor
        aboutMeField.layer.borderWidth = 0.6;
        aboutMeField.layer.cornerRadius = 6.0;
        
        mailingAddressField.layer.borderColor = borderColor.cgColor
        mailingAddressField.layer.borderWidth = 0.6;
        mailingAddressField.layer.cornerRadius = 6.0;
        
        aboutMeField.delegate = self
        mailingAddressField.delegate = self
        
        // Set about me and mailing address to what we have currently
        aboutMeField.text = profileDetail?.aboutMe ?? ""
        mailingAddressField.text = profileDetail?.address ?? ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Networking
    func updateProfile(about_me: String, address: String) {
        
        let userId = UserDefaults.standard.string(forKey: "user_id")
        
        // Send post request to complete registration
        let parameters: Parameters = [
            "user_id": userId!,
            "about_me": about_me,
            "address": address
        ]
        
        let urlPath = PostRoutes().updateUser
        
        HelperFunctions().sendPostRequest(urlPath: urlPath, parameters: parameters) {
            JSON, errorDescription in
            
            if JSON != nil {
                
                print("Updating user..")
                
                // Update profile detail
                var tempProfileDetail = self.profileDetail
                tempProfileDetail?.aboutMe = about_me
                tempProfileDetail?.address = address
                self.profileDetail = tempProfileDetail
                
                // Do unwindFromSettingsToProfileVC
                self.performSegue(withIdentifier: "unwindFromSettings", sender: self)
                
            }
            else if let error = errorDescription {
                // Display alert message
                HelperFunctions().displayAlertMessage(title: "Something went wrong", message: error, viewController: self)
            }
            else {
                print("No error but no JSON")
            }
        }
    }
    
    func logOut() {
        // Log out of facebook
        let loginManager = LoginManager()
        loginManager.logOut()
        
        // Reset user defaults
        UserDefaults.resetStandardUserDefaults()
        
        // Go back to log in screen
        self.performSegue(withIdentifier: "logoutSegue", sender: self)
    }
    
    func deleteAccount() {
        print("Deleting account...")
        
        let userId = UserDefaults.standard.string(forKey: "user_id")
        let urlPath = GetRoutes().removeUser + userId!
        
        HelperFunctions().sendGetRequest(urlPath: urlPath) {
            JSON, errorDescription in
            
            if let error = errorDescription {
                HelperFunctions().displayAlertMessage(title: "Something went wrong", message: error, viewController: self)
                return
            }
            else if JSON != nil {
                // Log me out
                print("Account deleted successfully...")
                self.logOut()
            }
            
        }
    }
    
    
    // MARK: - Text View
    // Truncates text views as user types
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        
        guard let stringRange = range.range(for: currentText) else { return false }
        
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        return changedText.characters.count <= maxTextViewLength
    }
    
    
    // MARK: - Buttons
    @IBAction func updateProfilePressed(_ sender: Any) {
        print("Pressed update profile")
        
        // Just in case our delegate does not work
        var about_me = aboutMeField.text ?? ""
        var address = mailingAddressField.text ?? ""
        
        
        if about_me.characters.count > maxTextViewLength {
            print ("About me is too long")
            
            HelperFunctions().displayAlertMessage(title: "Error", message: "About me is \(about_me.characters.count) characters long. It needs to be less than \(maxTextViewLength) characters.", viewController: self)
            return
        }
        
        if address.characters.count > maxTextViewLength {
            
            HelperFunctions().displayAlertMessage(title: "Error", message: "Address is \(address.characters.count) characters long. It needs to be less than \(maxTextViewLength) characters.", viewController: self)
            
            return
        }
        

         HelperFunctions().displayConfirmMessage(title: "Update Profile", message: "Are you sure you want to update your information?", viewController: self) {
         completed in
         
             if completed {
                 self.updateProfile(about_me: about_me, address: address)
             }
         }
    }
    
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        logOut()
    }
    
    
    @IBAction func deleteAccountPressed(_ sender: Any) {
        
        HelperFunctions().displayConfirmMessage(title: "Permanently Delete Account", message: "Are you sure? Your account and all its information will be removed. This cannot be undone.", viewController: self) {
            completed in
            
            if completed {
                self.deleteAccount()
            }
        }
    }
    
    
    
}
