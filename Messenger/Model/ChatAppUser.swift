//
//  ChatAppUser.swift
//  Flash Chat iOS13
//
//  Created by Mostafa Mahmoud on 1/9/22.
//  Copyright © 2022 Angela Yu. All rights reserved.
//

import Foundation
struct ChatAppUser {
    let email:String
    let firstName:String
    let secondName:String
    init(email:String,firstName:String,secondName:String)
    {
        self.email = email
        self.firstName = firstName
        self.secondName = secondName
        
    }
    var safeEmail:String
    {
        var safeemail = email.replacingOccurrences(of: ".", with: "-")
        safeemail = safeemail.replacingOccurrences(of: "@", with: "&")
        return safeemail
    
    }
    var profilePictureFileName:String
    {
        return ("\(email)_profile_picture.png")
    }
    
    
}
