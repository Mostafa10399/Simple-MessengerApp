//
//  RegisterViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase
import JGProgressHUD
class RegisterViewController: UIViewController {
    //MARK: - Outlets Declearation
    let spinner = JGProgressHUD(style: .dark)
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var secondNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    //MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        firstNameTextField.delegate=self
        secondNameTextField.delegate=self
        emailTextField.delegate=self
        passwordTextField.delegate=self
        // hna 3shan n3`yr al sora
        imageView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        
        imageView.addGestureRecognizer(gesture)
    }
    @objc func didTapChangeProfilePic()
    {
        presentPhotoActionSheet()
        
    }
    //MARK: - ViewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstNameTextField.layer.cornerRadius = firstNameTextField.frame.size.height/5
        firstNameTextField.layer.borderWidth = 1.0
        firstNameTextField.layer.borderColor = UIColor.lightGray.cgColor
        firstNameTextField.clipsToBounds = true
        firstNameTextField.setLeftPaddingPoints(10)
        secondNameTextField.layer.cornerRadius = secondNameTextField.frame.size.height/5
        secondNameTextField.layer.borderWidth = 1.0
        secondNameTextField.layer.borderColor = UIColor.lightGray.cgColor
        secondNameTextField.clipsToBounds = true
        secondNameTextField.setLeftPaddingPoints(10)
        emailTextField.layer.cornerRadius = secondNameTextField.frame.size.height/5
        emailTextField.layer.borderWidth = 1.0
        emailTextField.layer.borderColor = UIColor.lightGray.cgColor
        emailTextField.clipsToBounds = true
        emailTextField.setLeftPaddingPoints(10)
        passwordTextField.layer.cornerRadius = secondNameTextField.frame.size.height/5
        passwordTextField.layer.borderWidth = 1.0
        passwordTextField.layer.borderColor = UIColor.lightGray.cgColor
        passwordTextField.clipsToBounds = true
        passwordTextField.setLeftPaddingPoints(10)
        imageView.layer.cornerRadius = imageView.frame.size.height/2
        imageView.layer.borderWidth = 1.0
        imageView.clipsToBounds = true
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        registerButton.layer.cornerRadius = registerButton.frame.size.height/5
        registerButton.layer.borderWidth = 1.0
        registerButton.clipsToBounds = true
        registerButton.layer.borderColor = UIColor.lightGray.cgColor
        
        
    }
    
    //MARK: - ButtonPressed
    @IBAction func registerPressed(_ sender: UIButton) {
        spinner.show(in: view)
        if (emailTextField.text != "" && passwordTextField.text != "" && firstNameTextField.text != "" && secondNameTextField.text != "")
        { if let email = emailTextField.text , let password = passwordTextField.text {
            
            
            Auth.auth().createUser(withEmail: email, password: password) {[weak self] authResult, error in
                guard let strongSelf = self else
                {
                    return
                }
                DispatchQueue.main.async {
                    strongSelf.spinner.dismiss()
                }
                if let e = error
                {
                    print(e.localizedDescription)
                    let alert = UIAlertController(title: "Woops", message: e.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    strongSelf.present(alert, animated: true)
                    
                }

                
                else
                {
                    guard let firstName = strongSelf.firstNameTextField.text , let secondName = strongSelf.secondNameTextField.text else
                    {
                        return
                    }
                    print("Sigened UP")
                    UserDefaults.standard.set(email, forKey: K.email)
                    UserDefaults.standard.set("\(firstName) \(secondName)", forKey: K.name)
                    let chatUser = ChatAppUser(email: strongSelf.emailTextField.text!, firstName: strongSelf.firstNameTextField.text!, secondName: strongSelf.secondNameTextField.text!)
                    DataBaseManger.shared.insertUser(with:chatUser) { exist in
                        if exist
                        {
                            
                            if let image = strongSelf.imageView.image , let data = image.pngData()
                            {
                                let fileName = chatUser.profilePictureFileName
                                StorageManger.shared.uploadPictureCompletion(with: data, fileName: fileName) { result in
                                    
                                    switch result {
                                    case .success(let downloadURL):
                                        UserDefaults.standard.set(downloadURL,forKey: "profile_picture_url")
                                     
                                    case .failure(let error):
                                        print("storage manger error \(error)")
                                    }
                                }
                                
                            }
                        }
                    }
                    strongSelf.navigationController?.isNavigationBarHidden = true
                    strongSelf.performSegue(withIdentifier: K.segues.registertoChatSegue, sender: self)
                }
                
            }
        }
}
        else {
            let alert = UIAlertController(title: "Woops", message: "please enter all fields", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true)
            
        }
        
       
        
    }
}

//MARK: - UITEXTFIELDDELEGATE
extension RegisterViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        firstNameTextField.endEditing(true)
        secondNameTextField.endEditing(true)
        emailTextField.endEditing(true)
        passwordTextField.endEditing(true)
    }
    
    
}
//MARK: - ImagePickerControllerDelegate extension
extension RegisterViewController:UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func presentPhotoActionSheet(){
        let actionSheet=UIAlertController(title: "profile picture", message: "how would you like to select your profile picture", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take a photo", style: .default, handler: {[weak self] _ in
            
            self?.presentCamera()
        } ))
        actionSheet.addAction(UIAlertAction(title: "Choose photo", style: .default, handler: {[weak self] _ in
            self?.presentPhotoLibrary()
        }))
        present(actionSheet, animated: true)
        
        
    }
    func presentCamera(){
        
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    func presentPhotoLibrary()
    {
        let vc = UIImagePickerController()
        vc.delegate=self
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        present(vc, animated: true)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        print(info)
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        {
            imageView.image = selectedImage
        }
        
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    
    
}
