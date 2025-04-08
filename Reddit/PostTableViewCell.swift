//
//  PostTableViewCell.swift
//  Reddit
//
//  Created by Iryna on 25.03.2025.
//

import UIKit

protocol PostTableViewCellDelegate: AnyObject {
    func sharePost(_ cell: PostTableViewCell)
    func renewSave(_ cell: PostTableViewCell)
}

final class PostTableViewCell: UITableViewCell {
    weak var delegate: PostTableViewCellDelegate?
   
    @IBOutlet private weak var imgHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var postMetaDataLabel: UILabel!
    @IBOutlet private weak var bookmarkButton: UIButton!
    @IBOutlet private weak var postTitleLabel: UILabel!

    @IBOutlet private weak var postPreviewImg: UIImageView!
    @IBOutlet private weak var commentsLabel: UILabel!
    @IBOutlet private weak var ratingLabel: UILabel!
    
    
    @IBAction private func sharePostTab(_ sender: UIButton) {
        delegate?.sharePost(self)
    }
    
    @IBAction private func toggleSave(_ sender: UIButton) {
        delegate?.renewSave(self)
    }
    
    func updateBookmarkImage(isSaved: Bool) {
        let bookmarkImg = isSaved ? "bookmark.fill" : "bookmark"
        bookmarkButton.setImage(UIImage(systemName: bookmarkImg), for: .normal)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.postPreviewImg.sd_cancelCurrentImageLoad()
        self.postPreviewImg.image = nil
        self.imgHeightConstraint.constant = 0
        
    }
    
    func config(with post: Post){
        print("config cell")
        let metaData = [post.userName, post.timePassed, post.domain].joined(separator: " • ")
        self.postMetaDataLabel.text = metaData
        self.postTitleLabel.text = post.title
        self.ratingLabel.text = String(post.rating)
        self.commentsLabel.text = String(post.numComments)
        loadImage(from: post.imgURL)
        let bookmarkImg = post.saved ? "bookmark.fill" : "bookmark"
        self.bookmarkButton.setImage(UIImage(systemName: bookmarkImg), for: .normal)
    }
    
    private func loadImage(from url: String?) {
        guard let url = url, let imageUrl = URL(string: url) else {
            self.postPreviewImg.sd_cancelCurrentImageLoad()
            self.postPreviewImg.image = nil
            self.imgHeightConstraint.constant = 0
            return
        }
        self.postPreviewImg.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder"))
        self.imgHeightConstraint.constant = 220
        
    }
    
}
