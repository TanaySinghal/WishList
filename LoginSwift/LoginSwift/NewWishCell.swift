//
//  NewWishCell.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/21/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit


protocol NewWishCellDelegate {
    func newWishAdded(cell: NewWishCell, wish: String, wishDescription: String)
}


class NewWishCell: UITableViewCell, UITextViewDelegate {

    
    var newWishDelegate: NewWishCellDelegate?
    
    @IBOutlet weak var wishField: UITextField!
    @IBOutlet weak var wishDescriptionField: UITextView!
    
    @IBOutlet weak var addButton: UIButton!
    let descriptionPlaceholder = "Describe your wish..."
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        
        wishDescriptionField.layer.borderColor = UIColor(red: 215.0/255.0, green: 215.0/255.0, blue: 215.0/255.0, alpha: 1).cgColor
        wishDescriptionField.layer.borderWidth = 0.6;
        wishDescriptionField.layer.cornerRadius = 6.0;
        
        // Add placeholder to wishDescription
        // Describe your wish...
        wishDescriptionField.text = descriptionPlaceholder
        wishDescriptionField.textColor = UIColor.lightGray
        
        wishDescriptionField.delegate = self
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
    // For wish description place holder
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = descriptionPlaceholder
            textView.textColor = UIColor.lightGray
        }
    }
    
    // Add button
    @IBAction func addButton(_ sender: Any) {
        
        // Only if wishField is nonempty
        if let wishText = wishField.text {
            if let delegate = newWishDelegate {
                delegate.newWishAdded(cell: self, wish: wishText, wishDescription: wishDescriptionField.text ?? "")
            }
        }
        else {
            print ("Error from NewWishCell: wish is empty")
        }
        
    }

}
