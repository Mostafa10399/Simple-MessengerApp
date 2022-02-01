//
//  PhotoViewController.swift
//  Flash Chat iOS13
//
//  Created by Mostafa Mahmoud on 1/17/22.
//  Copyright © 2022 Angela Yu. All rights reserved.
//

import UIKit
import SDWebImage
class PhotoViewController: UIViewController {

    @IBOutlet weak var viewImage: UIImageView!
    var url:URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = url {
            navigationItem.largeTitleDisplayMode = .never
            view.backgroundColor = UIColor.black
            viewImage.sd_setImage(with: url, completed: nil)
        }


    }
    


}
