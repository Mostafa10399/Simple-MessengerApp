//
//  Conversation.swift
//  Flash Chat iOS13
//
//  Created by Mostafa Mahmoud on 1/15/22.
//  Copyright © 2022 Angela Yu. All rights reserved.
//

import Foundation
struct Conversation
{
    let id:String
    let name:String
    let otherUserEmail:String
    let latestMessage:LatestMessage
    
}
struct LatestMessage
{
    let date:String
    let text:String
    let isRead:Bool
}
