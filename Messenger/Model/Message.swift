//
//  MessageType.swift
//  Flash Chat iOS13
//
//  Created by Mostafa Mahmoud on 1/9/22.
//  Copyright © 2022 Angela Yu. All rights reserved.
//

import Foundation
import MessageKit
struct Message : MessageType
{
    var sender: SenderType
    
    var messageId: String
    
    var sentDate: Date
    
    var kind: MessageKind
    
    
}
extension MessageKind
{
    var MessageKindString:String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed Text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link Preview"
        case .custom(_):
            return "custom"
        }
    }
}
