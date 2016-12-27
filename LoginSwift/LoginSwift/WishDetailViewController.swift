//
//  WishDetailViewController.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/27/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit

class WishDetailViewController: UIViewController {

    @IBOutlet weak var wishLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var wishDetail: WishDetail?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        wishLabel.text = wishDetail!.wish
        descriptionLabel.text = wishDetail!.wishDescription
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
