//
//  ChatsViewController.swift
//  Flash Chat iOS13
//
//  Created by Mostafa Mahmoud on 1/5/22.
//  Copyright © 2022 Angela Yu. All rights reserved.
//

import UIKit
import Firebase
import JGProgressHUD
import SDWebImage
/// controller that shows list of conversation
class ChatsViewController: UIViewController {
    //MARK: - IBOutLits
    @IBOutlet weak var showConversationLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    //MARK: - variables
    var modelResult :Conversation?
    var conversation = [Conversation]()
    let spinner = JGProgressHUD(style: .dark)
    var results:SearchResult?
    var exists :Bool?
    var imageViews :UIImageView?
    var convID :String?
    var loginObserver:NSObjectProtocol?
    let button = UIButton(type: .custom)
    
    //MARK: - ViewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden=false
        startListingToConversation()
        tableView.reloadData()
    }
    
    //MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        tableView.register(UINib(nibName: K.ChatTableViewCell, bundle: nil), forCellReuseIdentifier: K.ChatCellIdentifire)
        tableView.delegate=self
        tableView.dataSource=self
        startListingToConversation()
        loginObserver=NotificationCenter.default.addObserver(forName: Notification.Name(K.loginObserver), object: nil, queue: .main, using: { _ in
            self.startListingToConversation()
            }
        )

        
    }
    
    //MARK: - ViewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden=false
        if let r = results
        {
            print(r)
        }
    }
    
    //MARK: - ViewDidDisappear
    override func viewDidDisappear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden=true
        
    }

    //MARK: - StartListeningForConversation
    func startListingToConversation()
    {
       
        if let email = UserDefaults.standard.value(forKey: K.email) as? String
        { print("reloded ")
            let safeEmail = DataBaseManger.SafeEmail(with: email)
            if let observer = loginObserver
            {
                NotificationCenter.default.removeObserver(observer)
            }
            
            
            
            DataBaseManger.shared.getAllConversations(Email: safeEmail) { [weak self]results in
                guard let strongSelf = self else
                {
                    return
                }
                switch results {
                case .success(var conversation):
               
                    if  !conversation.isEmpty
                    {
                        conversation.sort(by: {
                        let date1 =  ConversationViewController.dateFormatter.date(from: $0.latestMessage.date  )
                        let date2 = ConversationViewController.dateFormatter.date(from: $1.latestMessage.date )
                            guard let x1 = date1 , let x2 = date2 else
                            {
                                return false
                            }
                            return  x1.compare(x2) == .orderedDescending
                           
                            
                        })
                        strongSelf.conversation = conversation
                        DispatchQueue.main.async {
                            strongSelf.showConversationLabel.isHidden = true
                            strongSelf.tableView.isHidden = false
                            print("reloded data successfully")
                            strongSelf.tableView.reloadData()
                            
                        }
                    }
                    
                    else
                    {DispatchQueue.main.async {
                        strongSelf.tableView.isHidden = true
                        strongSelf.showConversationLabel.isHidden = false
                    }
                        
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        strongSelf.showConversationLabel.isHidden = false
                        strongSelf.tableView.isHidden = true
                        strongSelf.tableView.reloadData()
                        
                    }
                    print("failed to get convos \(error)")
                    
                }
                
            }
            
            
        }
    }
    //MARK: - newConversationButtonBressed
    @IBAction func newConversationButtonBressed(_ sender: UIBarButtonItem) {
        
        
        performSegue(withIdentifier: K.segues.ChatToNewChatSegue, sender: self)
        
        
    }
}


//MARK: - TableView
extension ChatsViewController : UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(conversation.count)
        return conversation.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversation[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: K.ChatCellIdentifire, for: indexPath) as! ChatTableViewCell
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        modelResult = conversation[indexPath.row]
        openConversation()
    }
    func openConversation()
    {
        performSegue(withIdentifier: K.segues.ChatToConversationSegue, sender: self)

    }
  
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete
        {
            // begin delete
            tableView.beginUpdates()
            let conversationID = conversation[indexPath.row].id
            self.conversation.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            DataBaseManger.shared.deleteConversation(conversationID: conversationID) { success in
         
                if !success
                {
                   
                    print("failed to delete")
                    
                }
                else
                {
                    print("cant")
                    
                }
                
            }
          
            
            tableView.endUpdates()
        }
    }
    
}
//MARK: - newConversationDelegate
extension ChatsViewController:NewConversationDelegate{
    
    
    func viewError(error: Error) {
        //
    }
    
    func makeNewConversation(_ newConversationViewController: NewConversationViewController, result: SearchResult) {
     
        DispatchQueue.main.async { 
            //lma bn3ml search btrg3lna result
            self.results=result
         //hna5od al conversations kolha w n3mlah unwrapped
            let currentConversation = self.conversation
            //hanshof al result aly gatlna deh mwgoda wla msh mwgoda
            if let targetConversation = currentConversation.first(where: {
                $0.otherUserEmail == DataBaseManger.SafeEmail(with: result.email)
            })
            {
                print("naghaaaam")
               
                print(targetConversation.id)
                //lw mwgoda han5od al conversation iD bta3ha
                self.convID = targetConversation.id
                //w n5ly al exist b false
                self.exists = false
            }
            else
            {
                //lw msh mwgoda n5ly al exist b true
                self.exists = true
            }
            self.performSegue(withIdentifier:K.segues.ChatToConversationSegue, sender: self)
        }
        
        
        
        
    }
    
    
    //MARK: - Prepare for segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let nav = segue.destination as? UINavigationController, let classBVC = nav.topViewController as? NewConversationViewController {
            classBVC.delegate = self
        }
        
        else if segue.identifier == K.segues.ChatToConversationSegue
        {
            if let destination = segue.destination as? ConversationViewController
            {
                //lw fe result atb3tet
                if let results = self.results
                {
                    //hanshof al lw al conversation dehh mwgoda abl kda yb2a exist = false & e = false
                    if let e=exists , e == true
                    {
                        //hanshof al conversation deh leha id wla la
                        DataBaseManger.shared.conversationExist(with: results.email) {[weak self] result in
                           
                            switch result
                            {
                                //lw leha id han5osh al conversation bnfs al id al adem
                            case .success(let conversationID):
                                print("the value of exist is = : \(e)")
                                destination.titleNames=results.name
                                destination.otherUserEmail=results.email
                                destination.isNewConversation=false
                                destination.conversationID = conversationID
                                self?.results = nil
                                //lw mlhash han3ml cinversation id gded
                            case .failure(_):
                                print("the value of exist is = : \(e)")
                                destination.titleNames=results.name
                                destination.otherUserEmail=results.email
                                destination.isNewConversation=true
                                self?.results = nil
                            }}
                        
                    }
                    //lw 3mlna search 3la conversation w tel3t mwgoda asln
                    else
                    {
                        if let convID = self.convID
                        {   destination.titleNames=results.name
                            destination.otherUserEmail = DataBaseManger.SafeEmail(with: results.email)
                            destination.isNewConversation=false
                            destination.conversationID=convID}}}
                // lw mafesh result atb3tet w a5trna al conversation aly 3yznha 3ltol
                else
                {if let model = modelResult{
                        destination.titleNames=model.name
                        destination.otherUserEmail=model.otherUserEmail
                        destination.isNewConversation=false
                        destination.conversationID=model.id}}
}
        }
        
        
    }
}
