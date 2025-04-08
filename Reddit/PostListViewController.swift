
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
    
    private var posts: [Post] = []
    private var savedPosts: [Post] = []
    private var after: String?
    private var dataLoader: DataLoader?
    private var isLoading = false
    private var isShowingSaved = false
    private var subreddit = "unknown"
    private var lastUpdatedIndex: Int?

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
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let updatedIndex = lastUpdatedIndex {
            tableView.reloadRows(at: [IndexPath(row: updatedIndex, section: 0)], with: .automatic)
            lastUpdatedIndex = nil
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
            cell.delegate = self
            cell.searchDelegate = self
            cell.config(subreddit: self.subreddit)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: Const.cellReuseIdentifier, for: indexPath) as! PostTableViewCell
        cell.delegate = self
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
        guard !isShowingSaved else { return }
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
            guard let selectedIdx = tableView.indexPathForSelectedRow else { return }
            let post = self.posts[selectedIdx.row - 1]
            let nextVc = segue.destination as! PostDetailsViewController
            nextVc.configure(with: post)
            nextVc.onSaveToggled = { [weak self] updatedPost in
                guard let self = self else { return }
                self.posts[selectedIdx.row - 1] = updatedPost
                self.tableView.reloadRows(at: [selectedIdx], with: .automatic)
                if(isShowingSaved){
                    if let index = savedPosts.firstIndex(where: { $0.id == updatedPost.id }) {
                        savedPosts[index] = updatedPost
                    }
                }
            }
            
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
extension PostListViewController: PostTableViewCellDelegate{
    func renewSave(_ cell: PostTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        var post = posts[indexPath.row - 1]
        
        post.saved.toggle()
        posts[indexPath.row - 1] = post
        
        SavedPostManager.shared.toggle(post: post)
        cell.updateBookmarkImage(isSaved: post.saved)
        
        if(isShowingSaved){
            if let index = savedPosts.firstIndex(where: { $0.id == post.id }) {
                savedPosts[index] = post
             }
        }
    }
    
    func sharePost(_ cell: PostTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let post = posts[indexPath.row-1]
        guard let url = URL(string: post.url) else { return }
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
}
extension PostListViewController: TableHeaderDelegate{
    func showPostsOnToggleSaved(_ showSaved: Bool) {
        self.isShowingSaved = showSaved
        posts = []
        if showSaved{
            
            savedPosts = SavedPostManager.shared.loadAll()
            posts = savedPosts
            after = nil
        }else{
            savedPosts = []
            dataLoader = nil
            Task { await fetchPage()}
        }
        tableView.reloadData()
    }
    
    
}
extension PostListViewController: UISearchBarDelegate{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard isShowingSaved else{return}
        if searchText.isEmpty{
            posts = savedPosts
        }else{
            posts = savedPosts.filter{
                $0.title.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
        if !searchText.isEmpty{
            DispatchQueue.main.async {
                self.focusSearchBar()
            }
        }
    }
    func focusSearchBar() {
        let header = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! PostListTableHeader
        header.makeSearchBarFirstResponder()
        
    }
}
