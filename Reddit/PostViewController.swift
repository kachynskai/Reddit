//
//  PostViewController.swift
//  Reddit
//
//  Created by Iryna on 10.03.2025.
//

import UIKit
import SDWebImage

final class PostViewController: UIViewController {
    private var dataLoader: DataLoader?

    @IBOutlet private weak var commentsLabel: UILabel!
    @IBOutlet private weak var ratingLabel: UILabel!
    @IBOutlet private weak var postPreviewImg: UIImageView!
    @IBOutlet private weak var postTitleLabel: UILabel!
    @IBOutlet private weak var bookmarkButton: UIButton!
    @IBOutlet private weak var postMetaDataLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        Task {
//            do {
//                let post = try await fetchPost(from: "https://www.reddit.com/r/ios/top.json?limit=2")
//                print(":dncjifdnvgijfg")
//                updateUI(with: post[0])
//            } catch {
//                print("Error: \(error)")
//            }
        }
    }
    
    private func updateUI(with post: Post) {
        
        let metaData = [post.userName, post.timePassed, post.domain].joined(separator: " • ")
        self.postMetaDataLabel.text = metaData
        self.postTitleLabel.text = post.title
        self.ratingLabel.text = String(post.rating)
        self.commentsLabel.text = String(post.numComments)
        let bookmarkImg = post.saved ? "bookmark.fill" : "bookmark"
        self.bookmarkButton.setImage(UIImage(systemName: bookmarkImg), for: .normal)
    }
    func loadImage(from url: String) {
        guard let imageUrl = URL(string: url) else { return }
        postPreviewImg.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder"))
    }
//    private func fetchPost(from path: String) async throws -> [Post]{
//        dataLoader = try DataLoader(path: path)
//        guard let posts = try await dataLoader?.getData() else {throw PostError.invalidPost}
//        for post in posts{
//            print("Current post: \(String(describing: post))")
//        }
//    
//        return posts
//    }

}
