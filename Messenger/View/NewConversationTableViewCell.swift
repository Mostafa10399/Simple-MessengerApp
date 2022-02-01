//
//  NewConversationTableViewCell.swift
//  Messenger
//
//  Created by Mostafa Mahmoud on 1/29/22.
//

import UIKit

class NewConversationTableViewCell: UITableViewCell {

    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    override func awakeFromNib() {
        
        super.awakeFromNib()
        // Initialization code
        profileImage.layer.cornerRadius = profileImage.frame.height/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func configure(with model:SearchResult)
    {
        userName.text = model.name
        var unSafeEmail = model.email
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
