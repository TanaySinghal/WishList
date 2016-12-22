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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Make text views look like text fields
        aboutMeField.layer.borderColor = UIColor(red: 215.0/255.0, green: 215.0/255.0, blue: 215.0/255.0, alpha: 1).cgColor
        aboutMeField.layer.borderWidth = 0.6;
        aboutMeField.layer.cornerRadius = 6.0;
        
        
        mailingAddressField.layer.borderColor = UIColor(red: 215.0/255.0, green: 215.0/255.0, blue: 215.0/255.0, alpha: 1).cgColor
        mailingAddressField.layer.borderWidth = 0.6;
        mailingAddressField.layer.cornerRadius = 6.0;
        
        // TODO: Limit letter count as user types
        // 16 char for username
        // 150 char for about me
        // 150 char for mailing address
        usernameField.delegate = self
        aboutMeField.delegate = self
        mailingAddressField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
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

    
    @IBAction func finishRegistration(_ sender: Any) {
        
        // Check if username is empty
        // Just in case, do something if it's too long
        
        var username = usernameField.text ?? ""
        var about_me = aboutMeField.text ?? ""
        var address = mailingAddressField.text ?? ""
        
        
        if username.characters.count > maxTextFieldLength ||
            username.characters.count < minUsernameLength {
            
            print ("Username needs to be between 4 and 16 characters.")
            return
        }
        
        if about_me.characters.count > maxTextViewLength {
            print ("About me is too long")
            return
        }
        
        if address.characters.count > maxTextViewLength {
            print ("Address is too long")
            return
        }
        
        // If address and about me are empty, make them ""
        
        
        // Send post request
        let parameters: Parameters = [
            "username": username,
            "about_me": about_me,
            "address": address
        ]
        
        let userSession = UserDefaults.standard
        let userId = userSession.string(forKey: "user_id") ?? ""
        
        // Send post request to database
        Alamofire.request("http://localhost:8080/user/update/" + userId, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            
            // New code
            
            switch response.result {
            case .success(let value):
                
                if let JSON = response.result.value {
                    print("User JSON:\n \(JSON)")
                    
                    // Save this data locally
                    userSession.set(username, forKey: "username")
                    userSession.set(about_me, forKey: "about_me")
                    userSession.set(address, forKey: "address")
                    
                    // Segue on
                    self.performSegue(withIdentifier: "finishedSignUp", sender: self)
                }
                else {
                    print("Failed to serialize JSON in OneMoreStepVC. Here is the result: \(value)")
                }
                
            case .failure(let error):
                print("Post request from OneMoreStepVC failed: \(error)")
            }
            // End new code
            
        }

        
        // Handle duplicate username error
        // Store everything in UserDefaults
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

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
