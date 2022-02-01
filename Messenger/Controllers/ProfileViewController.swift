//
//  ProfileViewController.swift
//  Flash Chat iOS13
//
//  Created by Mostafa Mahmoud on 1/5/22.
//  Copyright © 2022 Angela Yu. All rights reserved.
//
import FBSDKLoginKit
import UIKit
import Firebase
import GoogleSignIn
import JGProgressHUD
import SDWebImage
class ProfileViewController: UIViewController {
    let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    var data = [ProfileViewModel]()
    @IBOutlet weak var tableView: UITableView!
    //MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        getProfileInfo()
        data.append(ProfileViewModel(email: "Email:\(UserDefaults.standard.value(forKey: K.email) as? String ?? "no Email")", handler: nil))
        tableView.dataSource = self
        tableView.delegate = self
        profileImage.layer.cornerRadius = profileImage.frame.size.height/2
        profileImage.layer.borderWidth = 1.0
        profileImage.clipsToBounds = true
        profileImage.layer.borderColor = UIColor.lightGray.cgColor
        tableView.register(UINib(nibName: K.ProfileTableViewCell, bundle: nil), forCellReuseIdentifier:K.ProfileCellIdentifire)
        
    }
    //MARK: - Profile Info
    func getProfileInfo()
    {
        spinner.show(in: view)
        if let email = UserDefaults.standard.value(forKey: K.email) as? String
        {
            let fileName = "\(email)_profile_picture.png"
            let path="images/\(fileName)"
            print(path)
            userName.text=UserDefaults.standard.value(forKey: K.name) as? String
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
    
    @IBAction func logOutButtonPressed(_ sender: UIBarButtonItem) {

        let alert = UIAlertController(title: "log out", message: "are you sure that you want to log out", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {[weak self] _ in
            guard let strongSelf = self else
            {
                return
            }
            strongSelf.spinner.show(in: strongSelf.view)
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                
                strongSelf.spinner.dismiss()
                UserDefaults.standard.setValue(nil, forKey: K.email)
                UserDefaults.standard.setValue(nil, forKey: K.name)
                FBSDKLoginKit.LoginManager().logOut()
                GIDSignIn.sharedInstance().signOut()
                let firebaseAuth = Auth.auth()
                do {
                    try firebaseAuth.signOut()
                    print("signed out")
                    let rootViewController = strongSelf.view.window?.rootViewController as? UINavigationController
                    
                    rootViewController?.setViewControllers([rootViewController!.viewControllers.first!],
                                                           animated: false)
                    
                    rootViewController?.dismiss(animated: true, completion: nil)
                    
                    
                } catch let signOutError as NSError {
                    print("Error signing out: %@", signOutError)
                }
            }}))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            present(alert, animated: true)
            
            }

                                      
        
        
    
    
}
//MARK: - UITableViewDelegate

extension ProfileViewController : UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: K.ProfileCellIdentifire, for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            let viewModel = data[indexPath.row].handler?()
        }
    
}
