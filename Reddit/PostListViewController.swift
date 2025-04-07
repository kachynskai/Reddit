
import UIKit

final class PostListViewController: UITableViewController {
    
    struct Const {
        static let cellReuseIdentifier = "post_cell"
        static let headerReuseIdentifier = "post_list_header"
        static let numOfSections = 1
        static let postDetailsSegueId = "go_to_details"
        static let postsPerPage = "15"
    }
    
//    @IBOutlet private weak var subredditLabel: UILabel!
    
    private var posts: [Post] = [];
    private var after: String?
    private var dataLoader: DataLoader?
    private var isLoading = false
    private var subreddit = "unknown"

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: Const.cellReuseIdentifier)
        tableView.register(UINib(nibName: "PostListTableHeader", bundle: nil), forCellReuseIdentifier: Const.headerReuseIdentifier)
//        tableView.estimatedRowHeight = 150
//        tableView.rowHeight = UITableView.automaticDimension
        Task {
            await fetchPage()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        Const.numOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: Const.headerReuseIdentifier, for: indexPath) as! PostListTableHeader
            cell.config(subreddit: self.subreddit)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: Const.cellReuseIdentifier, for: indexPath) as! PostTableViewCell

        let post = self.posts[indexPath.row - 1]
        cell.config(with: post)
        return cell
    }
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        if cell?.reuseIdentifier == Const.headerReuseIdentifier{
            return nil
        }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: Const.postDetailsSegueId, sender: self)
    }
    
    // MARK: - Table view delegate
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let curY = scrollView.contentOffset.y
        let allPostsHeight = scrollView.contentSize.height
        let viewHeight = scrollView.frame.size.height
        
        if curY > allPostsHeight - viewHeight * 1.5{
            Task{
                await fetchPage()
            }
        }
    }
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier{
        case Const.postDetailsSegueId:
            let nextVc = segue.destination as! PostDetailsViewController
            if let selectedIndex = tableView.indexPathForSelectedRow{
                nextVc.configure(with: self.posts[selectedIndex.row - 1])
            }else{break}
        default:
            break
        }
    }
}
extension PostListViewController{
    
    private func fetchPage() async{
        guard !isLoading else { return }
        isLoading = true
        do {
            if dataLoader == nil {
                let path = "https://www.reddit.com/r/ios/top.json"
                dataLoader = try DataLoader(path: path)
                let subreddit = dataLoader?.getSubreddit() ?? "unknown"
                self.subreddit = subreddit
            }
            try dataLoader?.addParams(name: "limit", value: Const.postsPerPage)
            if let after = self.after {
                try dataLoader?.addParams(name: "after", value: after)
            }
            
            guard let (newPosts, newAfter) = try await dataLoader?.getData() else {throw PostError.invalidPost}
            self.posts.append(contentsOf: newPosts)
            self.after = newAfter

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Error loading new next page: \(error)")
        }
        isLoading = false
    }
    
}
