//
//  PostDetailsViewController.swift
//  Reddit
//
//  Created by Iryna on 31.03.2025.
//

import UIKit

final class PostDetailsViewController: UIViewController{
   
    struct Const {
        static let cellReuseIdentifier = "post_cell"
    }
    @IBOutlet private weak var singlePostTableView: UITableView!
    
    private var post: Post?
    var onSaveToggled: ((Post) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.singlePostTableView.delegate = self
        self.singlePostTableView.dataSource = self
        singlePostTableView.allowsSelection = false
        singlePostTableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: Const.cellReuseIdentifier)
    }
   
    func configure(with post: Post) {
        self.post = post
    }
}
extension PostDetailsViewController: UITableViewDelegate{
    
}
extension PostDetailsViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let post = self.post else {return UITableViewCell()}
        let cell = tableView.dequeueReusableCell(withIdentifier: Const.cellReuseIdentifier, for: indexPath) as! PostTableViewCell
        cell.delegate = self
        cell.config(with: post)
        return cell
    }
}
extension PostDetailsViewController: PostTableViewCellDelegate{
    func renewSave(_ cell: PostTableViewCell) {
        guard var post = self.post else { return }
        post.saved.toggle()
        SavedPostManager.shared.toggle(post: post)
        cell.updateBookmarkImage(isSaved: post.saved)
        self.post = post
        onSaveToggled?(post)
    }
    
    func sharePost(_ cell: PostTableViewCell) {
        guard let post = self.post, let url = URL(string: post.url) else { return }
        
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
}

