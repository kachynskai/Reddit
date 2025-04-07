//
//  PostDetailsViewController.swift
//  Reddit
//
//  Created by Iryna on 31.03.2025.
//

import UIKit

final class PostDetailsViewController: UIViewController {
    struct Const {
        static let cellReuseIdentifier = "post_cell"
    }
    @IBOutlet private weak var singlePostTableView: UITableView!
    
    private var post: Post?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.singlePostTableView.delegate = self
        self.singlePostTableView.dataSource = self
        singlePostTableView.allowsSelection = false
        singlePostTableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: Const.cellReuseIdentifier)
    }
   
    func configure(with post: Post){
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
        cell.config(with: post)
        return cell
    }

}

