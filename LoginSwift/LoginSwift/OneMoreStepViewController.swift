//
//  OneMoreStepViewController.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/21/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit
import Alamofire

class OneMoreStepViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var aboutMeField: UITextView!
    @IBOutlet weak var mailingAddressField: UITextView!
    
    let minUsernameLength = 4
    let maxTextFieldLength = 16
    let maxTextViewLength = 150
    
    var profileDetail: ProfileDetail?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Make text views look like text fields
        aboutMeField.layer.borderColor = UIColor(red: 215.0/255.0, green: 215.0/255.0, blue: 215.0/255.0, alpha: 1).cgColor
        aboutMeField.layer.borderWidth = 0.6;
        aboutMeField.layer.cornerRadius = 6.0;
        
        
        mailingAddressField.layer.borderColor = UIColor(red: 215.0/255.0, green: 215.0/255.0, blue: 215.0/255.0, alpha: 1).cgColor
        mailingAddressField.layer.borderWidth = 0.6;
        mailingAddressField.layer.cornerRadius = 6.0;
        
        
        usernameField.delegate = self
        aboutMeField.delegate = self
        mailingAddressField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Text Delegate Methods
    // Truncates text views as user types
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Truncate string
        let currentText = textField.text ?? ""
        guard let stringRange = range.range(for: currentText) else { return false }
        
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        return updatedText.characters.count <= maxTextFieldLength
    }
    
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        
        guard let stringRange = range.range(for: currentText) else { return false }
        
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        return changedText.characters.count <= maxTextViewLength
    }

    
    // MARK: - Button Pressed
    @IBAction func finishRegistration(_ sender: Any) {
        
        
        // Just in case our delegate does not work
        var username = usernameField.text ?? ""
        var about_me = aboutMeField.text ?? ""
        var address = mailingAddressField.text ?? ""
        
        
        if username.characters.count > maxTextFieldLength ||
            username.characters.count < minUsernameLength {
            
            HelperFunctions().displayAlertMessage(title: "Error", message: "Username needs to be between 4 and 16 characters.", viewController: self)
            return
        }
        
        if about_me.characters.count > maxTextViewLength {
            print ("About me is too long")
            
            HelperFunctions().displayAlertMessage(title: "Error", message: "About me is \(about_me.characters.count) characters long. It needs to be less than \(maxTextViewLength) characters.", viewController: self)
            return
        }
        
        if address.characters.count > maxTextViewLength {
            
            HelperFunctions().displayAlertMessage(title: "Error", message: "Address is \(address.characters.count) characters long. It needs to be less than \(maxTextViewLength) characters.", viewController: self)

            return
        }
        
        
        let userId = UserDefaults.standard.string(forKey: "user_id")
        
        // Send post request to complete registration
        let parameters: Parameters = [
            "user_id": userId!,
            "username": username,
            "about_me": about_me,
            "address": address
        ]
        
        let urlPath = PostRoutes().updateUser
        
        HelperFunctions().sendPostRequest(urlPath: urlPath, parameters: parameters) {
            JSON, errorDescription in
            
            if let json = JSON {
                print("User JSON:\n \(json)")
                
                
                if let oldProfileDetail = self.profileDetail {
                    
                    self.profileDetail = ProfileDetail(
                        id: userId!,
                        fbUserId: oldProfileDetail.fbUserId,
                        fullName: oldProfileDetail.fullName,
                        username: username,
                        aboutMe: about_me,
                        address: address,
                        profileState: oldProfileDetail.profileState,
                        strangerState: nil,
                        image: nil
                    )
                    
                    // Segue on
                    self.performSegue(withIdentifier: "finishedSignUp", sender: self)
                }
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

   
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "finishedSignUp" {
            
            let tabBarController = segue.destination as! UITabBarController
            let destNavController = tabBarController.viewControllers?.last as! UINavigationController
            
            let profileVC = destNavController.topViewController as! ProfileViewController
            
            profileVC.profileDetail = profileDetail
            
        }
    }
    

}

