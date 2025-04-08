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

protocol BookmarkAnimationDelegate: PostTableViewCellDelegate{}
final class PostTableViewCell: UITableViewCell {
    weak var delegate: PostTableViewCellDelegate?
    weak var animationDelegate: BookmarkAnimationDelegate?
   
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
        setupGesture()
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
    private func setupGesture(){
        postPreviewImg.gestureRecognizers?.forEach { postPreviewImg.removeGestureRecognizer($0) }
        postTitleLabel.gestureRecognizers?.forEach { postTitleLabel.removeGestureRecognizer($0) }
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(processDoubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
//        postPreviewImg.isUserInteractionEnabled = true
//        postPreviewImg.addGestureRecognizer(doubleTapRecognizer)
        if postPreviewImg.image != nil {
                postPreviewImg.isUserInteractionEnabled = true
                postPreviewImg.addGestureRecognizer(doubleTapRecognizer)
            } else {
                postTitleLabel.isUserInteractionEnabled = true
                postTitleLabel.addGestureRecognizer(doubleTapRecognizer)
            }
    }
    
    private func bookmarkBezierPath(width: CGFloat, height: CGFloat) -> UIBezierPath{
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: width/2, y: height-20))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.close()
        
        return path
    }
    
    
    @objc private func processDoubleTap(){
        DispatchQueue.main.async {
            self.drawBookmark()
        }
        animationDelegate?.renewSave(self)
    }
    
    
    
    private func drawBookmark() {
        let targetView: UIView = postPreviewImg.image != nil ? postPreviewImg : postTitleLabel
        let width: CGFloat = 40
        let height: CGFloat = 60
        
        let bookmarkLayer = makeBookmarkLayer(width: width, height: height, in: targetView)
        targetView.layer.addSublayer(bookmarkLayer)

        let animationGroup = makeFlyAnimation(
            from: bookmarkLayer.position,
            to: CGPoint(x: targetView.bounds.maxX - 30, y: targetView.bounds.minY + 20)
        )

        bookmarkLayer.add(animationGroup, forKey: "fly")

        DispatchQueue.main.asyncAfter(deadline: .now() + animationGroup.duration) {
            bookmarkLayer.removeFromSuperlayer()
        }
    }
    private func makeBookmarkLayer(width: CGFloat, height: CGFloat, in view: UIView) -> CAShapeLayer {
        let path = bookmarkBezierPath(width: width, height: height)
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.fillColor = UIColor(red: 208/255, green: 196/255, blue: 220/255, alpha: 0.62).cgColor
        layer.strokeColor = UIColor(red: 117/255, green: 63/255, blue: 108/255, alpha: 1.0).cgColor
        layer.lineWidth = 3
        layer.opacity = 1
        layer.position = CGPoint(x: view.bounds.midX - width / 2, y: view.bounds.midY - height / 2)
        return layer
    }
    
    
    
    private func makeFlyAnimation(from: CGPoint, to: CGPoint) -> CAAnimationGroup {
        
        
        let appear = CABasicAnimation(keyPath: "transform.scale")
        appear.fromValue = 0.3
        appear.toValue = 1.0
        appear.duration = 0.3
        appear.timingFunction = CAMediaTimingFunction(name: .easeOut)

        
        let scaleDown = CABasicAnimation(keyPath: "transform.scale")
        scaleDown.fromValue = 1.0
        scaleDown.toValue = 0.2
        scaleDown.beginTime = 0.3
        scaleDown.duration = 0.6
        scaleDown.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let move = CABasicAnimation(keyPath: "position")
        move.fromValue = from
        move.toValue = to
        move.beginTime = 0.3
        move.duration = 0.6
        move.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 1
        fadeOut.toValue = 0
        fadeOut.beginTime = 0.3
        fadeOut.duration = 0.6
        fadeOut.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let group = CAAnimationGroup()
        group.animations = [appear, scaleDown, move, fadeOut]
        group.beginTime = CACurrentMediaTime()
        group.duration = 0.9
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false

        
        return group
        
    }

}
