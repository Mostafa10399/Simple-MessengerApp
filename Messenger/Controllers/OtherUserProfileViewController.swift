//
//  OtherUserProfileViewController.swift
//  Flash Chat iOS13
//
//  Created by Mostafa Mahmoud on 1/28/22.
//  Copyright © 2022 Angela Yu. All rights reserved.
//

import UIKit
import JGProgressHUD
import SDWebImage
class OtherUserProfileViewController: UIViewController {
    //MARK: - variables
    let spinner = JGProgressHUD(style: .dark)
    var nameUser:String?
    var userEmail:String?
    //MARK: - IBOutlet
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var profileImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        getProfileInfo()
      
        profileImage.layer.cornerRadius = profileImage.frame.size.height/2
        profileImage.layer.borderWidth = 1.0
        profileImage.clipsToBounds = true
        profileImage.layer.borderColor = UIColor.lightGray.cgColor
       
    }
    
    //MARK: - Profile Info
    func getProfileInfo()
    {
        guard let emails = userEmail ,let name = nameUser else
        {
            return
        }
        var unSafeEmail = emails.replacingOccurrences(of: "&", with: "@")
        unSafeEmail = unSafeEmail.replacingOccurrences(of: "-", with: ".")
        spinner.show(in: view)
         let fileName = "\(unSafeEmail)_profile_picture.png"
            let path="images/\(fileName)"
            print(path)
            userName.text=name
            StorageManger.shared.downloadUrl(with: path) {[weak self] result in
                guard let strongSelf = self else
                {
                    return
                }
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        strongSelf.profileImage.sd_setImage(with: url, completed: nil)
                        strongSelf.spinner.dismiss()
                    }
                case .failure(let error):
                    print("failed because\(error)")
                }
            }
        
      
    }
    //MARK: - ViewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden=false
    }
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden=false
    }
    //MARK: - ViewDidDisappear
    override func viewDidDisappear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden=true
        
    }
    



}
