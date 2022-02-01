
import UIKit
import JGProgressHUD
import RealmSwift
//MARK: - Delegate Design Pattern
protocol NewConversationDelegate: AnyObject
{
    func viewError(error:Error)
    func makeNewConversation(_ newConversationViewController:NewConversationViewController,result:SearchResult)
}

class NewConversationViewController: UIViewController {
    
    //MARK: - IBOutlet
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    //MARK: - Variables
    weak var delegate:NewConversationDelegate?
    var completion:(([String:String])->(Void))?
    let spinner = JGProgressHUD(style: .dark)
    var users = [[String:String]]()
    var results = [SearchResult]()
    var hasFetched = false
    //MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden=true
        searchBar.delegate=self
        navigationItem.titleView = searchBar
        tableView.dataSource=self
        tableView.delegate=self
        tableView.register(UINib(nibName: K.NewConversationTableViewCell, bundle: nil), forCellReuseIdentifier: K.NewConversationTableViewCell)
        resultLabel.isHidden=true
        tableView.isHidden=true
        
        
        
    }

    
    //MARK: - Cancel Button
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true)
        
    }
    
    
}
//MARK: - Search Bae Delegate
extension NewConversationViewController:UISearchBarDelegate
{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text
        {
            text.replacingOccurrences(of: " ", with: "")
            if !text.isEmpty
            {
                results.removeAll()
                spinner.show(in: view)
                searchUsers(query: text)
                
            }
        }
        
    }
    //MARK: - Search Users
    func searchUsers(query:String)
    {
        if !hasFetched
        {
            DataBaseManger.shared.getAllUsers {[weak self] result in
                guard let strongSelf = self else
                {
                    return
                }
                switch result {
                case .success(let collection):
                    strongSelf.users=collection
                    
                    strongSelf.hasFetched=true
                    strongSelf.filterUsers(with: query)
                case.failure(let error):
                    print("failed to get users\(error)")
                }
            }
        }
        else
        {
            filterUsers(with: query)
        }
        
    }
    //MARK: - Filter User
    func filterUsers(with term:String)
    {
        guard let currentUser = UserDefaults.standard.value(forKey: "email") as? String ,hasFetched else
        {
            return
        }
        let safeEmail = DataBaseManger.SafeEmail(with: currentUser)
        
            spinner.dismiss()
            
            let results : [SearchResult] = self.users.filter({
                guard let email = $0["Email"] , email != safeEmail else{
                    return false
                }
                
                guard let name = $0["Name"]?.lowercased() else
                {
                    return false
                }
                
                    print(name)
                    print(name.hasPrefix(term.lowercased()))
                    return name.hasPrefix(term.lowercased())
               
                
            }).compactMap ({
                
                guard let email = $0["Email"] ,let name = $0["Name"] else{
                    return nil
                }
                
                return SearchResult(name: name, email: email)
            })
            self.results = results
            
            
        
        updateUI()
    }
    //MARK: - Update UI
    func updateUI()
    {
        if results.isEmpty
        {
            resultLabel.text = "there is no results to show"
            resultLabel.textColor = UIColor.red
            resultLabel.isHidden=false
            tableView.isHidden=true
            
        }
        else
        {
            resultLabel.isHidden=true
            tableView.isHidden=false
            tableView.reloadData()
            
        }
    }
}
//MARK: - Table DataSource and Delegate
extension NewConversationViewController:UITableViewDataSource,UITableViewDelegate
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: K.NewConversationTableViewCell, for: indexPath) as! NewConversationTableViewCell
        print(results[indexPath.row])
      
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        print(results[indexPath.row])
        let targetResults = results[indexPath.row]
        print(targetResults)
        dismiss(animated: false, completion: nil)
        self.delegate?.makeNewConversation(self,result: targetResults)
        
        
    }
    
    
    
}
