//
//  WelcomeViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD
class WelcomeViewController: UIViewController  {
    let spinner = JGProgressHUD(style: .dark)
    @IBOutlet weak var googleSigninButton: GIDSignInButton!
    
    @IBOutlet weak var fbButton: FBLoginButton!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var emailLabel: UITextField!
    
    @IBOutlet weak var passwordLabel: UITextField!
    private var loginObserver : NSObjectProtocol?
    private var spinnerShow : NSObjectProtocol?

    
    //MARK: - View will Appear

    
    //MARK: - View DidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor(named: K.BrandColors.lighBlue)
        GIDSignIn.sharedInstance()?.presentingViewController = self
        spinnerShow=NotificationCenter.default.addObserver(forName: Notification.Name(K.addObserverSpinner), object: nil, queue: .main, using: {[weak self] _ in
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                strongSelf.spinner.show(in: strongSelf.view)
            }
            
        })
        loginObserver=NotificationCenter.default.addObserver(forName: Notification.Name(K.loginObserver), object: nil, queue: .main, using: {[weak self] _ in
            guard let strongSelf = self else
            {
                return
            }
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            strongSelf.performSegue(withIdentifier: K.segues.LogInToChatSegue, sender: strongSelf)
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            strongSelf.navigationController?.isNavigationBarHidden = true
            
        })
       
        emailLabel.delegate = self
        passwordLabel.delegate = self
        validateAuth()
        fbButton.delegate=self
        if let token = AccessToken.current,
           !token.isExpired {
            // User is logged in, do work such as go to next view controller.
        }
        fbButton.permissions = ["public_profile", "email"]
        
    }
    deinit {
        if let obeserver = loginObserver
        {
            NotificationCenter.default.removeObserver(obeserver)
        }
    }
    //MARK: - ViewDid Disapper
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    //MARK: - didpPressedButton
   public func didpPressedButton()
    {
        spinner.show(in: view)
    }
    
    //MARK: - ViewDidAppear
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.isNavigationBarHidden = false
        emailLabel.layer.cornerRadius = emailLabel.frame.size.height/5
        emailLabel.layer.borderWidth = 1.0
        emailLabel.layer.borderColor = UIColor.lightGray.cgColor
        passwordLabel.layer.cornerRadius = passwordLabel.frame.size.height/5
        passwordLabel.layer.borderWidth = 1.0
        passwordLabel.layer.borderColor = UIColor.lightGray.cgColor
        passwordLabel.layer.masksToBounds = true
        emailLabel.setLeftPaddingPoints(10)
        passwordLabel.setLeftPaddingPoints(10)
        loginButton.layer.cornerRadius = loginButton.frame.size.height/5
        loginButton.layer.borderWidth = 1.0
        
    }
    
    
    //MARK: - ButtonPressed Function
    @IBAction func buttonPressed(_ sender: UIButton) {
        
        spinner.show(in: view)
        if let email = emailLabel.text , let password = passwordLabel.text{
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
                guard let strongSelf = self else
                {
                    return
                }
                DispatchQueue.main.async {
                    strongSelf.spinner.dismiss()
                }
                if let e = error {
                    let alert = UIAlertController(title: "Woops", message: e.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "dissmis", style: .cancel, handler: nil))
                    strongSelf.present(alert, animated: true)}
                else
                {
                    let safeEmail = DataBaseManger.SafeEmail(with: email)
                    UserDefaults.standard.set(email, forKey: K.email)
                    DataBaseManger.shared.getDataFor(with: safeEmail) { result in
                        switch result {
                        case .success(let user):
                            let firstName = user["First Name"] as? String
                            let secondName = user["Second Name"] as? String
                            if let fN = firstName ,let sN = secondName
                            {
                                let name="\(fN) \(sN)"
                                UserDefaults.standard.set(name, forKey: K.name)

                            }
                           
                        case .failure(let error):
                            print("failed to get data for \(safeEmail) : \(error)")
                        }
                    }
                
                    
                    
                    
                    strongSelf.navigationController?.isNavigationBarHidden = true
                    strongSelf.validateAuth()
                    print("logged in")
                    
                }
                
            }
        }
        
        
        else{
            
            let alert = UIAlertController(title: "Woops", message: "please enter username and password", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "dissmis", style: .cancel, handler: nil))
            present(alert, animated: true)}
    }
    //MARK: - View Will Appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        emailLabel.text=""
        passwordLabel.text=""
        FBSDKLoginKit.LoginManager().logOut()
        GIDSignIn.sharedInstance().signOut()
        emailLabel.placeholder="Email"
        passwordLabel.placeholder="Password"
        validateAuth()
    }
    //MARK: - Validate Function
    func validateAuth()
    {
        
        if let x = FirebaseAuth.Auth.auth().currentUser{
            print(x)
            navigationController?.isNavigationBarHidden = true
            performSegue(withIdentifier: K.segues.LogInToChatSegue, sender: self)
            
            
        }
        
        
    }
    
    
    
    
}

//MARK: - TextField
extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.size.height))
        leftView = paddingView
        leftViewMode = .always
        
    }
}


//MARK: - UITEXTFIELDDELEGATE
extension WelcomeViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        passwordLabel.endEditing(true)
        emailLabel.endEditing(true)
    }
    
    
}
//MARK: - login to facebook
extension WelcomeViewController:LoginButtonDelegate
{
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // print nothing
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        if let token = result?.token?.tokenString
        {
            spinner.show(in: view)
            let faceBookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                             parameters: ["fields": "id, email, name, first_name, last_name, picture.type(large)"],
                                                             tokenString: token,
                                                             version: nil,
                                                             httpMethod: .get)
            faceBookRequest.start { connection, result, error in
                if let e = error
                {
                    print(e.localizedDescription)
                }
                else {
                    if let r = result as? [String:Any]
                    {
                        print (r)
                        if let firstName = r[K.FB.firstName] as? String , let email = r[K.FB.email] as? String, let lastName = r[K.FB.lastName] as? String ,let profilePicture = r[K.FB.picture] as? [String:Any],let data = profilePicture[K.FB.data] as? [String:Any],let pictureURL = data[K.FB.url] as? String
                            
                        {
                            
                          
                            UserDefaults.standard.set(email, forKey: K.email)
                            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: K.name)
                            DataBaseManger.shared.existUser(with: email,completion: { exist in
                                if !exist
                                {
                                    print(!exist)
                                    
                                  
                                    let chatUser = ChatAppUser(email: email, firstName: firstName, secondName: lastName)
                                    DataBaseManger.shared.insertUser(with:chatUser)
                                    { success in
                                        if success
                                        {
                                            if let url = URL(string: pictureURL)
                                            {
                                                URLSession.shared.dataTask(with: url) { data, urlResponse, error in
                                                    if let data = data
                                                    {
                                                        let fileName = chatUser.profilePictureFileName
                                                        StorageManger.shared.uploadPictureCompletion(with: data, fileName: fileName) { result in
                                                            switch result {
                                                            case .failure(let error):
                                                                print("storage manger error \(error)")
                                                                
                                                            case .success(let downloadURL):
                                                                UserDefaults.standard.set(downloadURL,forKey: "profile_picture_url")
                                                                
                                                    }}}
                                                }.resume()}}}}
                                
                            })}
                    }
                    
                }
                let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
                Firebase.Auth.auth().signIn(with: credential) {[weak self] authResult, error in
                    guard let strongSelf = self else
                    {
                        return
                    }
                    if let e = error
                    {
                        print(e.localizedDescription)
                    }
                    strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                    strongSelf.navigationController?.isNavigationBarHidden = true
                    strongSelf.spinner.dismiss()
                    strongSelf.performSegue(withIdentifier: K.segues.LogInToChatSegue, sender: self)
                }}}}}


