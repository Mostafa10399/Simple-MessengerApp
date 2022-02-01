//
//  ConversationViewController.swift
//  Flash Chat iOS13
//
//  Created by Mostafa Mahmoud on 1/8/22.
//  Copyright © 2022 Angela Yu. All rights reserved.
import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation
class ConversationViewController: MessagesViewController {
    //MARK: - IBOutLets

    @IBOutlet weak var titleButton: UIButton!
    
    //MARK: - Variables
    static var dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    var senderPhotorURL:URL?
    var otherPhotorURL:URL?
    var didPressed:Bool?
    var locationToSend:CLLocationCoordinate2D?
    var location = LocationPickerViewController()
    var imageURL:URL?
    var conversationID:String?
    var titleNames:String?
    var messages = [Message]()
    var isNewConversation:Bool?
    var otherUserEmail:String?
    let currentUserEmail = UserDefaults.standard.value(forKey: K.email)
    var senderUser : Sender? {
        if var email = UserDefaults.standard.value(forKey: K.email) as? String
        {
            email=DataBaseManger.SafeEmail(with: email)
            return  Sender(senderId: email , photoURL: "", displayName: "me")
        }
        else
        {
            return nil
        }
        
        
    }
  
    //MARK: - ViewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let id = conversationID
        {
            
            LissenForMessages(id:id)
        }

    }
    
    //MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource=self
        messagesCollectionView.messagesLayoutDelegate=self
        messagesCollectionView.messageCellDelegate=self
        messagesCollectionView.reloadDataAndKeepOffset()
        messagesCollectionView.messagesDisplayDelegate=self
        
        messagesCollectionView.delegate=self
        messageInputBar.delegate=self
        navigationItem.titleView?.isUserInteractionEnabled = true
        self.scrollsToLastItemOnKeyboardBeginsEditing = false
        if let name = titleNames
        {
            navigationItem.title=name
            navigationItem.largeTitleDisplayMode = .never
            titleButton.setTitle(name, for:.normal )
        }
        
                if let id = conversationID
                {
                    LissenForMessages(id:id)
                }
    
       
        setupInputButton()
    }

    @IBAction func userInfoPressed(_ sender: UIButton) {
        performSegue(withIdentifier: K.segues.ChatToProfile, sender: self)
    }
    //MARK: - Setup Input Button
    func    setupInputButton()
    {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside {[weak self] _ in
            self?.presenetPhotoCameraSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    //MARK: - LissenForMessages
    func LissenForMessages(id:String)
    {
        guard let email = otherUserEmail else
        {
            return
        }
        DataBaseManger.shared.getAllMessagesForConversation(with: id,to : email) {[weak self] results in
            guard let strongSelf = self else
            {
                return
            }
            
            switch results {
            case .success(let message):
                print(message)
                if  !message.isEmpty
                {
                    print("messages is not empty")
                    strongSelf.messages = message
                    DispatchQueue.main.async {
                        strongSelf.messagesCollectionView.reloadDataAndKeepOffset()
                        strongSelf.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("messages is  empty")
                print("Failed to get all messages : \(error)")
                
            }
        }
    }
    
}

//MARK: - InputBarAccessoryViewDelegate
extension ConversationViewController:InputBarAccessoryViewDelegate
{
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        if !(text.replacingOccurrences(of: " ", with: "").isEmpty)
        {
            
          
            if let selfSender = self.senderUser , let messageID = createMessageID() ,let isNew = isNewConversation
            {
                let message = Message(sender: selfSender,
                                      messageId: messageID,
                                      sentDate: Date(),
                                      kind: .text(text))
                if isNew
                {
                    
                    if let otherUserEmail = otherUserEmail
                    {
                        DataBaseManger.shared.createNewConvesation(with: otherUserEmail,name:self.titleNames ?? "user", firstMessage: message)
                        {[weak self] success in
                            guard let strongSelf = self else
                            {
                                return
                            }
                            
                            if success
                            {
                                print("message sent")
                                strongSelf.isNewConversation = false
                                let newConversationID = "conversation_\(message.messageId)"
                                DispatchQueue.main.async {
                                    strongSelf.LissenForMessages(id: newConversationID)
                                    strongSelf.messagesCollectionView.reloadDataAndKeepOffset()
                                    strongSelf.messagesCollectionView.scrollToLastItem()
                                    strongSelf.conversationID=newConversationID
                                    strongSelf.messageInputBar.inputTextView.text = nil
                             
                                    
                                   
                                 
                                }
                                
                                
                            }
                            else
                            {
                                print("failed to send")
                            }}}}
                else
                {
                    if let conversationID = self.conversationID ,let email = otherUserEmail,let name = titleNames
                    {
                        let safeEmail = DataBaseManger.SafeEmail(with: email)
                        DataBaseManger.shared.sendMessage(otherUserEmail:safeEmail,name:name,to: conversationID, newMessage: message) {[weak self] success in
                            if success
                            {
                                print("appended message successfully")
                                DispatchQueue.main.async {
                                    self?.messageInputBar.inputTextView.text = nil

                                }
                            }
                            else
                            {
                                print("didint appended message ")
                                
                            }
                        }
                        // append
                    }}
                
            }}}
}


//MARK: - MessagesDataSource,MessagesLayoutDelegate,MessagesDisplayDelegate,
extension ConversationViewController:MessagesDataSource,MessagesLayoutDelegate,MessagesDisplayDelegate ,MessageCellDelegate,AVPlayerViewControllerDelegate
{
   
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == senderUser?.senderId
        {
            // our message that we have sent
            return .link
            
        }
        else
        {
            return .secondarySystemBackground
        }
    }
    
    func currentSender() -> SenderType {
        if let sender = senderUser
        {
            return sender
        }
        else
        {
            fatalError("self sender is nil email shoud be cashed")
        }
    }
    
    
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        print("messagesCollectionView ->MessageType")
        print( messages[indexPath.section])
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        print("messagesCollectionView ->Int")
        print(messages.count)
        return messages.count
    }
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind
        {
            
        case .text(_):
            break
        case .attributedText(_):
            break
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            imageView.sd_setImage(with: imageURL, completed: nil)
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
    }
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else
        {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind
        {
            
        case .text(_):
            break
        case .attributedText(_):
            break
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            
            self.imageURL = imageURL
            performSegue(withIdentifier: K.segues.ChatToPhoto, sender: self)
        case .video(let media):
            guard let videoURL = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.delegate=self
            let player = AVPlayer(url: videoURL)
            
            vc.player = player
            
            present(vc, animated: true)
            player.play()
            
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            locationToSend = coordinates
            didPressed = true
            performSegue(withIdentifier: K.segues.ConversationToLocation, sender: self)
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
        
    }
        
    
    //MARK: - Did tap image
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else
        {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind
        {
            
        case .text(_):
            break
        case .attributedText(_):
            break
        case .photo(let media):
            guard let imageURL = media.url else {
                return
            }
            
            self.imageURL = imageURL
            performSegue(withIdentifier: K.segues.ChatToPhoto, sender: self)
        case .video(let media):
            guard let videoURL = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.delegate=self
            let player = AVPlayer(url: videoURL)
            
            vc.player = player
            
            present(vc, animated: true)
            player.play()
            
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
        
    }
}
extension ConversationViewController
{
    //MARK: - Create Message ID
    func createMessageID()->String?
    {
        
        // date ,otherUserEmail,SenderUserEmail randomInt
        
        if var UserEmail = currentUserEmail as? String , let OtherUserEmail = otherUserEmail
        {
            
            UserEmail = DataBaseManger.SafeEmail(with: UserEmail)
            
            let newIdentefire = "\(OtherUserEmail) _\(UserEmail)_\(Self.dateFormatter.string(from: Date()))"
            print ("created new message identfire \(newIdentefire)")
            return newIdentefire
            
        }
        return nil
        
    }
 func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
     
     let sender = message.sender
     if  sender.senderId == senderUser?.senderId
     {
         //show our image
         if let currentUserImageURL = self.senderPhotorURL
         {DispatchQueue.main.async {
             avatarView.sd_setImage(with: currentUserImageURL, completed: nil)

         }
             
         }
         else
         {
             //fetch URL
             guard let email = UserDefaults.standard.value(forKey: K.email) as? String else
             {
                 return
             }
             let path = "images/\(email)_profile_picture.png"
             StorageManger.shared.downloadUrl(with: path) {[weak self] result in
                 guard let strongSelf = self else
                 {return}
                 switch result {
                 case .success(let url):
                     strongSelf.senderPhotorURL = url
                     DispatchQueue.main.async {
                         avatarView.sd_setImage(with: url, completed: nil)
                         messagesCollectionView.reloadData()


                     }
                 case .failure(let error):
                     print("failed to fetch image : \(error)")
                 }
             }
         }
     }
     else
     {
         //other user image
         if let otherUserImageURL = self.otherPhotorURL
         {
             avatarView.sd_setImage(with: otherUserImageURL, completed: nil)

         }
         else
         {
             //fetch URL
             guard let safeEmail = otherUserEmail  else
             {
                 return
             }
             var email = safeEmail.replacingOccurrences(of: "&", with: "@")
             email = email.replacingOccurrences(of: "-", with: ".")
             let path = "images/\(email)_profile_picture.png"
             StorageManger.shared.downloadUrl(with: path) { result in
                 switch result {
                 case .success(let url):
                     self.otherPhotorURL = url
                     DispatchQueue.main.async {
                         avatarView.sd_setImage(with: url, completed: nil)
                         messagesCollectionView.reloadData()


                     }
                 case .failure(let error):
                     print("failed to fetch image : \(error)")
                 }
             }
         }
     }
     
   
      
}
}
//MARK: -  UI IMagePicker
extension ConversationViewController:UIImagePickerControllerDelegate ,UINavigationControllerDelegate
{
    func presenetPhotoCameraSheet()
    {
        let actionSheet = UIAlertController(title: "Attach media", message: "What would you like to attach", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: {[weak self] _ in
            self?.presesntPhotoAtcionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {[weak self] _ in
            self?.presesntVideoAtcionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: {[weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    
    //MARK: - present Location Picker
    func presentLocationPicker()
    {
        performSegue(withIdentifier: K.segues.ConversationToLocation, sender: self)
        
    }
    //MARK: - present video action sheet
    func presesntVideoAtcionSheet()
    {
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to attach video from ?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] _ in
            self?.presentVideoCamera()
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: {[weak self] _ in
            self?.presentVideoLibrary()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    //MARK: - present camera video function
    func presentVideoCamera()
    {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.delegate=self
        vc.mediaTypes = ["public.movie"]
        vc.videoQuality = .typeMedium
        present(vc,animated: true)
        
        
    }
    //MARK: - present library video function
    func presentVideoLibrary()
    {
        
        let vc = UIImagePickerController()
        vc.delegate=self
        vc.sourceType = .photoLibrary
        vc.mediaTypes = ["public.movie"]
        vc.videoQuality = .typeMedium
        vc.allowsEditing = true
        present(vc,animated: true)
        
    }
    
    //MARK: -  present an image action sheet
    func presesntPhotoAtcionSheet()
    {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach photo from ?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] _ in
            self?.presentPhotoCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: {[weak self] _ in
            self?.presentPhotoLibrary()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    //MARK: - present camera image function
    func presentPhotoCamera()
    {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.delegate=self
        present(vc,animated: true)
        
        
    }
    //MARK: - present library image function
    func presentPhotoLibrary()
    {
        
        let vc = UIImagePickerController()
        vc.delegate=self
        vc.sourceType = .photoLibrary
        vc.allowsEditing = true
        present(vc,animated: true)
        
    }
    //MARK: - imagePickerControllerDidCancel
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    //MARK: - Picking the media we want
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        picker.dismiss(animated: true, completion: nil)
        
        if let messageID = createMessageID(), let conversationID = conversationID , var otherUserEmail = otherUserEmail,let name = titleNames , let selfSender = senderUser
        {
            if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage , let imageData = image.pngData()
            {
                //uploadImage
                otherUserEmail = DataBaseManger.SafeEmail(with: otherUserEmail)
                let fileName = "photo_message_" + messageID.replacingOccurrences(of: " ", with: "-")+".png"
                StorageManger.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { result in
                    switch result {
                    case .success(let urlString):
                        
                        print("uploaded Message Image \(urlString)")
                        guard let url = URL(string: urlString),let placeHolder = UIImage(systemName: "plus") else
                        {return}
                        let media = Media(url: url, image: nil, placeholderImage: placeHolder, size: .zero)
                        let message = Message(sender: selfSender,
                                              messageId: messageID,
                                              sentDate: Date(),
                                              kind: .photo(media))
                        DataBaseManger.shared.sendMessage(otherUserEmail: otherUserEmail, name: name, to: conversationID, newMessage: message) { success in
                            if success
                            {
                                print("message sent")
                            }
                            else
                            {
                                print("message couldnt send")
                            }
                            //
                        }
                    case .failure(let error):
                        print("failed to send image message \(error)")
                    }
                }
            }
            //upload video
            else if let videoURL = info[.mediaURL] as? URL{
                
                otherUserEmail = DataBaseManger.SafeEmail(with: otherUserEmail)
                let fileName = "photo_message_" + messageID.replacingOccurrences(of: " ", with: "-")+".mov"
                StorageManger.shared.uploadMessageVideo(with: videoURL , fileName: fileName) { result in
                    switch result {
                    case .success(let urlString):
                        
                        print("uploaded Message Video \(urlString)")
                        guard let url = URL(string: urlString),let placeHolder = UIImage(systemName: "plus") else
                        {return}
                        let media = Media(url: url,
                                          image: nil,
                                          placeholderImage: placeHolder,
                                          size: .zero)
                        
                        let message = Message(sender: selfSender,
                                              messageId: messageID,
                                              sentDate: Date(),
                                              kind: .video(media))
                        DataBaseManger.shared.sendMessage(otherUserEmail: otherUserEmail, name: name, to: conversationID, newMessage: message) { success in
                            if success
                            {
                                print("message sent")
                            }
                            else
                            {
                                print("message couldnt send")
                            }
                            //
                        }
                    case .failure(let error):
                        print("failed to send video message \(error)")
                    }
                }
                
                
            }
            
            //uploadImage
            
            //sendMessage
        }
    }
    
}
//MARK: - Location Picker Delegate
extension ConversationViewController:LocationPickerDelegate
{
    func viewError(error: Error) {
        print(error)
        
    }
    //MARK: - send coodinate
    func sendCordinate(_ newLocation: LocationPickerViewController, cordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            print ("iam in conv Location")
            let longitude :Double = cordinate.longitude
            let latitude :Double = cordinate.latitude
            print(longitude)
            print(latitude)
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                    size: .zero)
            if let messageID = self.createMessageID()
                , let conversationID = self.conversationID
                , let otherUserEmail = self.otherUserEmail,
               let name = self.titleNames ,
               let selfSender = self.senderUser
            {
                
                let message = Message(sender: selfSender,
                                      messageId: messageID,
                                      sentDate: Date(),
                                      kind: .location(location))
                DataBaseManger.shared.sendMessage(otherUserEmail: otherUserEmail, name: name, to: conversationID, newMessage: message) { success in
                    if success
                    {
                        print("message location sent")
                    }
                    else
                    {
                        print("message location couldnt send")
                    }}}}
    }
    //MARK: - prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print(segue.destination)
        if  segue.identifier == K.segues.ConversationToLocation
        {
            guard let destinationViewController = segue.destination as? LocationPickerViewController else { return }
            destinationViewController.delegate = self
            if let isTrue = self.didPressed
            {
                if let destination = segue.destination as? LocationPickerViewController
                {
                    destination.coordinatesSend = self.locationToSend
                    destination.isPickable = false
                    
                }
                self.didPressed=nil
            }
            else
            {
                if let destination = segue.destination as? LocationPickerViewController
                {
                    destination.isPickable = true
                    
                }
            }
            
            
            
        }
        else if segue.identifier == K.segues.ChatToPhoto
        {
            if let destination = segue.destination as? PhotoViewController
            {
                destination.url = self.imageURL
                
            }
        }
        else if segue.identifier == K.segues.ChatToProfile
        {
            if let destination = segue.destination as? OtherUserProfileViewController
            {
                guard let otherUser = otherUserEmail , let name = titleNames else
                   {
                       return
                   }
                destination.userEmail = otherUser
                destination.nameUser = name
                
            }
        }
    }
}
    
    

