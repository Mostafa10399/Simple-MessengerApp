




//
//  DataBaseManger.swift
//  Flash Chat iOS13
//
//  Created by Mostafa Mahmoud on 1/4/22.
//  Copyright © 2022 Angela Yu. All rights reserved.
//
import CoreLocation
import Foundation
import FirebaseDatabase
import Firebase
import CoreMedia
import MessageKit

class DataBaseManger{
   
   
   static func SafeEmail(with email:String)->String
   {
       var emailAddress = email.replacingOccurrences(of: ".", with: "-")
       emailAddress = emailAddress.replacingOccurrences(of: "@", with: "&")
       return emailAddress
       
   }
   
   
  //    let ref = Database.database().reference()
   static let shared = DataBaseManger()
   private let database = Database.database().reference()
   //MARK: - Exist User
   /// check if user exist for givern email
   /// Parameters
   /// - 'Email' :               Target email to be checked
   /// - 'completion' :      Async closures to return with result
   func existUser(with emailAddress:String , completion: @escaping ((Bool)->Void))
   {
       let email = DataBaseManger.SafeEmail(with: emailAddress)
       
       
       database.child(email).observeSingleEvent(of: .value) { snapShot in
           
           guard snapShot.value as?[String:Any] != nil else
           {
               completion(false)
               return
           }
               completion(true)
           
           
           
           
               
               
           }
       }
   
   
   //MARK: - Insert User
   func insertUser(with user:ChatAppUser,completion:@escaping (Bool)->Void)
   
   {//1
       database.child(user.safeEmail).setValue(["First Name":user.firstName,
                                                "Second Name":user.secondName,
                                                "Email Address":user.safeEmail])
       {[weak self] error, _ in//2
           guard let strongSelf = self else
           {
               return
           }
           if let e = error
           {
               print("failed at write to database: \(e)")
               completion(false)
           }
           else
           {//3
               strongSelf.database.child("users").observeSingleEvent(of: .value)
               { snapShot in //4
                   if var usersCollection = snapShot.value as? [[String:String]]
                   { //5
                       
                       let newElement  = [ "Name":user.firstName + " " + user.secondName
                                           ,"Email":user.safeEmail
                                           
                       ]
                       usersCollection.append(newElement)
                       strongSelf.database.child("users").setValue(usersCollection)
                       { error, refrence in //6
                           if let error = error { //7
                               completion(false)
                               print(error.localizedDescription)
                           } //7
                           else{
                               completion(true)
                           }
                       } //6
                   }//5
                   else
                   { //5
                       let newCollection:[[String:String]] = [[ "Name":user.firstName + " " + user.secondName
                                                                ,"Email":user.safeEmail
                                                                
                                                              ]]
                       strongSelf.database.child("users").setValue(newCollection)
                       { error, refrence in //6
                           if let error = error {
                               print(error)
                               completion(false)
                           }
                           else
                           {
                               completion(true)
                           }
                       } //6
                   } //5
                   
               }//4
               
           }//3
           
       }//2
   }//1
   
   //MARK: - Get All Users
   ///Get all users from database
   func getAllUsers(completion:@escaping (Result<[[String:String]],Error>)->Void)  {
       database.child("users").observeSingleEvent(of: .value) { snapShot in
           if let users = snapShot.value as? [[String:String]]
           {
               completion(.success(users))
           }
           else
           {
               completion(.failure(customError.failedToFetch))
           }
       }
       
       
   }
   //MARK: - Error cnum
   
   enum customError:Error
   {
       case failedToFetch
       var localizedDescription :String{
           switch self
           {
           case .failedToFetch:
               return "this mean blah failed"
           }
       }
   }
   
   
}
//MARK: - Sending Message To Conversation
extension DataBaseManger
{
   /// create new conversation and send the first message
   func createNewConvesation(with OtherUserEmail:String,name:String ,firstMessage : Message,completion :@escaping (Bool)->Void)
   {

       
       var message = ""
       switch firstMessage.kind
       {
           
       case .text(let messageText):
           message = messageText
           
       case .attributedText(_):
           break
       case .photo(_):
           break
       case .video(_):
           break
       case .location(_):
           break
       case .emoji(_):
           break
       case .audio(_):
           break
       case .contact(_):
           break
           
       case .linkPreview(_):
           break
           
       case .custom(_):
           break
           
       }
       if let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,let nameOther = UserDefaults.standard.value(forKey: "name") as? String
       {
           let messageDate = firstMessage.sentDate
           let dateString = ConversationViewController.dateFormatter.string(from: messageDate)
           var collectionMessage :[String:Any] = [:]
           let safeEmail = DataBaseManger.SafeEmail(with: currentEmail)
           let ref = database.child(safeEmail)
           ref.observeSingleEvent(of: .value) {[weak self] snapShot in
               guard let strongSelf = self else
               {
                   return}
               if var userNode = snapShot.value as? [String:Any]
               {
                           if let curretnUserEmail = UserDefaults.standard.value(forKey: "email") as? String
                           {
                               let safeMail = DataBaseManger.SafeEmail(with: curretnUserEmail)
                               collectionMessage = [
                                   "id" : firstMessage.messageId,
                                   "type" : firstMessage.kind.MessageKindString,
                                   "content" : message,
                                   "date" : dateString,
                                   "sender_email" : safeMail ,
                                   "is_read" : false,
                                   "name":name
                               ]
                  
                           }
                   let conversationID = "conversation_\(firstMessage.messageId)"
                   let messageDate = firstMessage.sentDate
                   let dateString = ConversationViewController.dateFormatter.string(from: messageDate)
                   let newConversationData :[String:Any] = [
                       "id": conversationID,
                       "other_user_email":OtherUserEmail,
                       "name":name,
                       "latest_message":[
                           "date": dateString,
                           "message":message,
                           "is_read":false
                       ],
                       "messagesCollection":[collectionMessage]
                   ]
                   let recpient_newConversationData :[String:Any] = [
                       "id": conversationID,
                       "other_user_email":safeEmail,
                       "name":nameOther,
                       "latest_message":[
                           "date": dateString,
                           "message":message,
                           "is_read":false
                       ],
                       "messagesCollection":[collectionMessage]

                   ]
                   
                   // update recpient conversation entry
                   strongSelf.database.child("\(OtherUserEmail)/conversations").observeSingleEvent(of: .value) { snapShot in
                       if var conversation = snapShot.value as? [[String:Any]]
                       {
                           //append
                           conversation.append(recpient_newConversationData)
                           strongSelf.database.child("\(OtherUserEmail)/conversations").setValue(conversation)
                           
                           
                       }
                       else
                       {
                           //Creation Case
                           strongSelf.database.child("\(OtherUserEmail)/conversations").setValue([recpient_newConversationData])
                           
                       }
                   }
                   
                   //update current user entery
                   if var conversations = userNode["conversations"] as? [[String:Any]]
                   {
                       // conversation exist for current user
                       //you should append
                       conversations.append(newConversationData)
                       userNode["conversations"] = conversations
                       
                       ref.setValue(userNode) { error, _ in
                           if let error = error {
                               print(error.localizedDescription)
                               completion(false)
                           }
                           else
                           {
                               strongSelf.finishCreatingConversation(name:name,conversationID: conversationID, firstMessage: firstMessage, completion: completion)                            }
                       }
                   }
                   else
                   {
                       // conversation is not exist
                       //create it
                       userNode["conversations"] =
                       [
                           newConversationData
                       ]
                       ref.setValue(userNode) { error, _ in
                           if let error = error {
                               print(error.localizedDescription)
                               completion(false)
                           }
                           else
                           {
                               strongSelf.finishCreatingConversation(name:name,conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                               
                           }
                       }
                   }
               }
               else
               {
                   print("user not found")
                   completion(false)
               }
           }
           
       }
       
   }
   func finishCreatingConversation(name:String,conversationID:String,firstMessage:Message,completion:@escaping (Bool)->Void)
   {
       
       var message = ""
       switch firstMessage.kind
       {
           
       case .text(let messageText):
           message = messageText
           
       case .attributedText(_):
           break
           
       case .photo(_):
           break
           
       case .video(_):
           break
           
       case .location(_):
           break
           
       case .emoji(_):
           break
           
       case .audio(_):
           break
           
       case .contact(_):
           break
           
       case .linkPreview(_):
           break
           
       case .custom(_):
           break
           
       }
       var collectionMessage :[String:Any] = [:]
       let messageDate = firstMessage.sentDate
       let dateString = ConversationViewController.dateFormatter.string(from: messageDate)
       if let curretnUserEmail = UserDefaults.standard.value(forKey: "email") as? String
       {
           let safeMail = DataBaseManger.SafeEmail(with: curretnUserEmail)
           collectionMessage = [
               "id" : firstMessage.messageId,
               "type" : firstMessage.kind.MessageKindString,
               "content" : message,
               "date" : dateString,
               "sender_email" : safeMail ,
               "is_read" : false,
               "name":name
           ]
           
       }
       else
       {
           completion(false)
       }
       let value :[String:Any] = [
           "messages":[collectionMessage]
           
       ]
       database.child(conversationID).setValue(value) { error, _ in
           if let error = error
           {
               print (error)
               completion(false)
           }
           else
           {
               completion(true)
           }
       }
   }
   /// fetch and return all conversations for the user passed by email
   func getAllConversations(Email:String,completion:@escaping(Result<[Conversation],Error>)->Void)
   {
       print("get all conversation")
       database.child("\(Email)/conversations").observe(.value) { snapShot in
           if let value = snapShot.value as? [[String:Any]]
           {
               let conversation :[Conversation] = value.compactMap { dictionary in
                   
                   if let conversationID = dictionary["id"] as? String,let otherUserEmail = dictionary["other_user_email"] as? String,let name = dictionary["name"] as? String, let latestMessage = dictionary["latest_message"] as? [String:Any],let date = latestMessage["date"] as? String,let message = latestMessage["message"] as? String , let isRead = latestMessage["is_read"] as? Bool
                   {
                       print(conversationID)
                       let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                       print("returned successfully")
                       return Conversation(id: conversationID, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
                   }
                   else
                   {
                       return nil
                   }
                   
               }
               print(conversation)
               completion(.success(conversation))
           }
           else
           {
               completion(.failure(customError.failedToFetch))
           }
           
           
           
       }
       
   }
   //MARK: - get all messages
   /// gives all messages for a given conversation
   func getAllMessagesForConversation(with id:String,to otherUserEmail:String,completion:@escaping(Result<[Message],Error>)->Void)
   {
       guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else
       {
           return
       }
       let safeMail = DataBaseManger.SafeEmail(with: currentEmail)
       database.child("\(safeMail)/conversations").observe(.value) { snapShot in
           if let value = snapShot.value as? [[String:Any]]
           {
               let specficConversation = value.first {
                   guard let targetSenderEmail = $0["id"] as? String else
                   {
                       return false
                   }
                   return targetSenderEmail == id
               }
               guard let conv = specficConversation else
               {
                   return
               }
               let messageCollerction = conv["messagesCollection"] as? [[String:Any]]
               guard let mc = messageCollerction else
               {
                   return
               }
               
               let messages :[Message] = mc.compactMap { dictionary in
                   if let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let messageId = dictionary["id"] as? String ,
                      let isRead = dictionary["is_read"] as? Bool ,
                       let name = dictionary["name"] as? String,
                      let senderEmail = dictionary["sender_email"] as?
                       String,let type = dictionary["type"] as? String,
                      let date = ConversationViewController.dateFormatter.date(from: dateString)
                   {
                       print("sender has sent successfully")
                       var kind :MessageKind?
                       if type == "photo"
                       {
                           guard let imageURL = URL(string: content), let placeHolder = UIImage(systemName: "plus") else{
                               return nil
                           }
                           
                           let media = Media(url: imageURL,
                                             image: nil,
                                             placeholderImage: placeHolder
                                             , size: CGSize(width: 300, height: 300))
                           kind = .photo(media)
                       }
                       else if type == "video"
                       {
                           guard let videoURL = URL(string: content), let placeHolder = UIImage(systemName: "play.circle") else{
                               return nil
                           }
                           
                           let media = Media(url: videoURL,
                                             image: nil,
                                             placeholderImage: placeHolder
                                             , size: CGSize(width: 300, height: 300))
                           kind = .video(media)
                       }
                       else if type == "location"
                       {
                           let locationComponants = content.components(separatedBy: ",")
                          guard let longitude = Double(locationComponants[0]) ,let latitude = Double(locationComponants[1])  else
                          {
                              return nil
                          }
                           let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                                   size: CGSize(width: 300, height: 300))
                           kind = .location(location)
                       }
                       else
                       {
                           kind = .text(content)
                       }
                       guard let finalKind = kind else
                       {
                           return nil
                       }
                       let sender = Sender(senderId: senderEmail
                                           , photoURL: ""
                                           , displayName: name)
                       
                       
                       
                       return Message(sender:sender
                                      , messageId:messageId
                                      , sentDate: date
                                      , kind: finalKind)
                       
                       
                   }
                   else
                   {
                       return nil
                   }
                   
                   
                   
               }
               completion(.success(messages))
           }
           else
           {
               completion(.failure(customError.failedToFetch))
           }
           
           
           
       }
       
       
       
   }
   /// send messages with target conversation
   //MARK: - Send Messages
   func sendMessage(otherUserEmail:String,name:String,to conversationID:String,newMessage:Message,completion:@escaping(Bool)->Void )
   {//add new message to messages//update sender latest message//update recpient latest message
       
       self.database.child("\(conversationID)/messages").observeSingleEvent(of: .value) {[weak self] snapShot in
           guard let strongSelf = self else
           {
               return}
           if var currentMessages = snapShot.value as? [[String:Any]]
           {
               var message = ""
               switch newMessage.kind
               {
               case .text(let messageText):
                   message = messageText
               case .attributedText(_):
                   break
               case .photo(let mediaItem):
                   if let targetURLString = mediaItem.url?.absoluteString
                   {
                       message = targetURLString
                   }
                   
                   break
               case .video(let mediaItem):
                   if let targetURLString = mediaItem.url?.absoluteString
                   {
                       message = targetURLString
                   }
                   break
               case .location(let locationData):
                   let location = locationData.location
                   message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                   break
               case .emoji(_):
                   break
               case .audio(_):
                   break
               case .contact(_):
                   break
               case .linkPreview(_):
                   break
               case .custom(_):
                   break
               }
               var newMessageEntry :[String:Any] = [:]
               let messageDate = newMessage.sentDate
               let dateString = ConversationViewController.dateFormatter.string(from: messageDate)
               if let curretnUserEmail = UserDefaults.standard.value(forKey: "email") as? String
               {
                   let safeMail = DataBaseManger.SafeEmail(with: curretnUserEmail)
                   newMessageEntry = [
                       "id" : newMessage.messageId,
                       "type" : newMessage.kind.MessageKindString,
                       "content" : message,
                       "date" : dateString,
                       "sender_email" : safeMail ,
                       "is_read" : false,
                       "name":name]
                   
                   
                   
               }
               if let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String
               {
                   let updatedValue:[String:Any] = [
                       "date":dateString,
                       "message":message,
                       "is_read":false
                   ]
                   var databaseEnteryConversation = [[String:Any]]()
                   let safeEmail = DataBaseManger.SafeEmail(with: currentUserEmail)
                   
                   ///current user
                   strongSelf.database.child("\(safeEmail)/conversations").observeSingleEvent(of: .value) { snapShot in
                       if var currentUserConversation = snapShot.value as? [[String:Any]]
                       {   var pos = 0
                           var targetConversation :[String:Any]?
                           for conversation in currentUserConversation
                           {
                               if let currentID = conversation["id"] as? String , currentID == conversationID
                               {
                                   targetConversation = conversation
                                   break
                               }
                               pos += 1
                           }
                           if var targetConversation = targetConversation
                           {
                               targetConversation["latest_message"] = updatedValue
                                guard var newData =  targetConversation["messagesCollection"] as? [[String:Any]] else
                                {
                                    return
                                }
                               newData.append(newMessageEntry)
                               targetConversation["messagesCollection"] = newData
                               currentUserConversation[pos] = targetConversation
                               databaseEnteryConversation = currentUserConversation
                           }
                           else
                           {
                               let newConversationData :[String:Any] = [
                                   "id": conversationID,
                                   "other_user_email":DataBaseManger.SafeEmail(with: otherUserEmail),
                                   "name":name,
                                   "latest_message":updatedValue,
                                   "messagesCollection":[newMessageEntry]
                               ]
                               currentUserConversation.append(newConversationData)
                               databaseEnteryConversation = currentUserConversation

                               
                           }
                           }
                           
                        // lw al conversation msh mwgoda hay3ml conversation gdeda
                       else
                       {
                           
                           let newConversationData :[String:Any] = [
                               "id": conversationID,
                               "other_user_email":DataBaseManger.SafeEmail(with: otherUserEmail),
                               "name":name,
                               "latest_message":updatedValue,
                               "messagesCollection":[newMessageEntry]
                           ]
                           databaseEnteryConversation = [
                               
                                   newConversationData
                                   
                               
                           
                           ]
                           
                       }
                       ///han7ot data bta3t conversaion
                       strongSelf.database.child("\(safeEmail)/conversations").setValue(databaseEnteryConversation) { error, _ in
                               if let error = error {
                                   print(error)
                                   completion(false)
                               }
                               else
                               {
                                   // update LatestMessage for receving
                                 
                                   var databaseEnteryConversation = [[String:Any]]()
                                   let updatedValue:[String:Any] = [
                                       "date":dateString,
                                       "message":message,
                                       "is_read":false
                                   ]
                                   guard let userName = UserDefaults.standard.value(forKey: "name") as? String else
                                   {
                                       return
                                   }
                                   strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapShot in
                                       if var otherUserConversation = snapShot.value as? [[String:Any]]
                                       {
                                          
                                           var pos = 0
                                           var targetConversation :[String:Any]?
                                           for conversation in otherUserConversation
                                           {
                                               if let currentID = conversation["id"] as? String , currentID == conversationID
                                               {
                                                   targetConversation = conversation
                                                   break
                                               }
                                               pos += 1
                                           }
                                           if var targetConversation = targetConversation
                                           {
                                               targetConversation["latest_message"] = updatedValue
                                               guard var newData =  targetConversation["messagesCollection"] as? [[String:Any]] else
                                               {
                                                   return
                                               }
                                              newData.append(newMessageEntry)
                                              targetConversation["messagesCollection"] = newData
                                               otherUserConversation[pos] = targetConversation
                                               databaseEnteryConversation = otherUserConversation
                                           }
                                           else
                                           {
                                               //failed to fined in current collection
                                               let newConversationData :[String:Any] = [
                                                   "id": conversationID,
                                                   "other_user_email":safeEmail,
                                                   "name":userName,
                                                   "latest_message":updatedValue,
                                                   "messagesCollection":[newMessageEntry]
                                               ]
                                               otherUserConversation.append(newConversationData)
                                               databaseEnteryConversation = otherUserConversation
                                           }
                                       }
                                       else
                                       {
                                           //current collection doesnt exist
                                           
                                           let newConversationData :[String:Any] = [
                                               "id": conversationID,
                                               "other_user_email":safeEmail,
                                               "name":userName,
                                               "latest_message":updatedValue,
                                               "messagesCollection":[newMessageEntry]
                                           ]
                                           databaseEnteryConversation = [
                                               
                                                   newConversationData
                                                   
                                               
                                           
                                           ]
                                           
                                       }
                                       strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEnteryConversation) { error, _ in
                                               if let error = error {
                                                   print(error)
                                                   completion(false)
                                               }
                                               else
                                               {
                                                   completion(true)
                                               }}}}}}}
               currentMessages.append(newMessageEntry)
               strongSelf.database.child("\(conversationID)/messages").setValue(currentMessages) { error, _ in
                   if let error = error {
                       print(error)
                       completion(false)
                   }
                   else
                   {
                       completion(true)
                   }
               }
               
           }
           else
           {
               completion(false)}}}}








   extension DataBaseManger
   {
       /// return dictinary node at child path
       func getDataFor(with path:String,completion:@escaping (Result<[String:Any],Error>)->Void)
       {
           database.child(path).observeSingleEvent(of: .value) { snapShot in
               if let user = snapShot.value as? [String:Any]
               {
                   completion(.success(user))
               }
               else
               {
                   completion(.failure(customError.failedToFetch))
               }
               
           }
       }
   }
//MARK: - deleation Function
extension DataBaseManger
{
   /// check if the target conversion is exist or not by the id
   func conversationExist(with targetRecpientEmail:String , completion:@escaping(Result<String,Error>)->Void)
   {
       let safeRecepientEmail = DataBaseManger.SafeEmail(with: targetRecpientEmail)
       guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else
       {return}
       let safeSenderUserEmail = DataBaseManger.SafeEmail(with: currentUserEmail)
       database.child("\(safeRecepientEmail)/conversations").observeSingleEvent(of: .value) { snapShot in
           guard let collection = snapShot.value as? [[String:Any]] else
           {
               completion(.failure( customError.failedToFetch))
               return
           }
           //iterate and find conversation with target sender
           if let conversation = collection.first(where:{
               guard let targetSenderEmail = $0["other_user_email"] as? String else
               {
                   return false
               }
               
               return safeSenderUserEmail == targetSenderEmail
           })
           {
               // get id
               guard let id = conversation["id"] as? String else
               {
                       completion(.failure( customError.failedToFetch))
                       return
               }
               completion(.success(id))
               return
               
           }
           else
           {
               completion(.failure( customError.failedToFetch))
               return
           }
           
       }
   }
   
   
   /// delete a target conversation by id 
   func deleteConversation (conversationID :String , completion:@escaping (Bool)->Void )
   {
       print("deleting conversation with id : \(conversationID)")
       guard let email = UserDefaults.standard.value(forKey: "email") as? String else
       {
           return
       }
       let safeEmail = DataBaseManger.SafeEmail(with: email)
       database.child("\(safeEmail)/conversations").observeSingleEvent(of: .value) {[weak self] snapShot in
           guard let strongSelf = self else
           {
               return}
           if var conversations = snapShot.value as? [[String:Any]]
           {
               var positionToRemove = 0
               for conversation in conversations
               {
                   if let id = conversation["id"] as? String , id == conversationID
                   {
                       print("found conversation to delete")
                       break
                   }
                   positionToRemove += 1
               }
               conversations.remove(at: positionToRemove)
               strongSelf.database.child("\(safeEmail)/conversations").setValue(conversations) { error, _ in
                   if let e = error {
                       print("failed to delete conversation :\(e)")
                       completion(false)
                   }
                   else
                   {
                       print("deleted conversation successfully")
                       completion(true)
                   }
               }
               
           }
           
         
           
       }
       
   }

}
