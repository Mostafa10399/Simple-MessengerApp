//
//  ChatTableViewCell.swift
//  Messenger
//
//  Created by Mostafa Mahmoud on 1/29/22.
//

import UIKit

class ChatTableViewCell: UITableViewCell {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var messageBudy: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        profileImage.layer.cornerRadius = profileImage.frame.height/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func configure(with model:Conversation)
    {
        userName.text = model.name
        messageBudy.text = model.latestMessage.text
        var unSafeEmail = model.otherUserEmail
        unSafeEmail = unSafeEmail.replacingOccurrences(of: "&", with: "@")
        unSafeEmail = unSafeEmail.replacingOccurrences(of: "-", with: ".")
        let path = "images/\(unSafeEmail)_profile_picture.png"
        StorageManger.shared.downloadUrl(with: path) { result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self.profileImage.sd_setImage(with: url, completed: nil)
                }
               
            case .failure(let error):
                print("failed to fetch: \(error)")
                
            
            }
        }
    }
    
}
