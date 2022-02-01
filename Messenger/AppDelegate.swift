//
//  AppDelegate.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.


// AppDelegate.swift
import UIKit
import IQKeyboardManagerSwift
import JGProgressHUD
import FBSDKCoreKit
import Firebase
import GoogleSignIn
@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate   {
    let wvc=WelcomeViewController()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
//            IQKeyboardManager.shared.enable = true
//        IQKeyboardManager.shared.enable = true
//        IQKeyboardManager.shared.enableAutoToolbar=false
//        IQKeyboardManager.shared.shouldResignOnTouchOutside=true
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = "1075667978712-cgtercg9nj1rd8hagdhlmjg91nc3gtcb.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self
        
        
        
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
            
        )
        return GIDSignIn.sharedInstance().handle(url)
    }
   
    
    
    
    
}

//MARK: - GIDSignInDelegate

extension AppDelegate : GIDSignInDelegate
{
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        print("user hello")
        if let e = error
        {
            print("failed to log in with google \(e)")
        }
        guard
            let authentication = user?.authentication,
            let idToken = authentication.idToken
        else {
            return
        }
        if let u = user {
            print("signed in with user\(u)")
        }
       
        if let email = user.profile.email, let firstName = user.profile.givenName ,let secondName = user.profile.familyName  {
            NotificationCenter.default.post(name: Notification.Name("SpinnerShow"), object: nil)

            
            DataBaseManger.shared.existUser(with: email) { exist in
                if !exist
                {
                    if user.profile.hasImage
                    {
                        if let url = user.profile.imageURL(withDimension: 200)
                        {
                            let chatUser = ChatAppUser(email: email, firstName: firstName  , secondName:secondName )
                            let fileName = chatUser.profilePictureFileName
                            UserDefaults.standard.set(email, forKey: "email")
                            UserDefaults.standard.set("\(firstName) \(secondName)" , forKey: "name")

                            URLSession.shared.dataTask(with: url) { data, response, error in
                                if let data = data {
                                    DataBaseManger.shared.insertUser(with: chatUser) { success in
                                        if success
                                        {
                                            StorageManger.shared.uploadPictureCompletion(with: data, fileName: fileName) { result in
                                                switch result {
                                                case .success(let downloadURL):
                                                    UserDefaults.standard.set(downloadURL,forKey: "profile_picture_url")
                                                    print(downloadURL)
                                                    
                                                case .failure(let error):
                                                    print("storage manger error \(error)")
                                                }
                                                
                                            }
                                        }
                                    }
                                }
                                
                                
                            }.resume()
                            
                            
                        }
                    }
                }
                
            }
            
            
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: authentication.accessToken)
        Firebase.Auth.auth().signIn(with: credential) { authResult, error in
            if let e = error
            {
                print("failed to login with google credintial\(e)")
                return
            }
            else
            {
                print("signed in Successfuly with gmail")
                NotificationCenter.default.post(name: Notification.Name("DidLogInNotification"), object: nil)
                
                
            }
            
        }
        
    }
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user was discoonected")
    }
}



