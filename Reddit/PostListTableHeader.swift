//
//  PostListTableHeader.swift
//  Reddit
//
//  Created by Iryna on 07.04.2025.
//
import UIKit
protocol TableHeaderDelegate: AnyObject{
    func showPostsOnToggleSaved(_ showSaved: Bool)
}

final class PostListTableHeader: UITableViewCell{
    
    weak var delegate: TableHeaderDelegate?
    weak var searchDelegate: UISearchBarDelegate?
    private var showSaved = false
    @IBOutlet private weak var subredditLabel: UILabel!
    @IBOutlet private weak var searchBarConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var savedButton: UIButton!
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBAction private func showSavedToggle(_ sender: UIButton) {
        self.showSaved.toggle()
        resetSearchBar()
        updateButtonStyle()
        delegate?.showPostsOnToggleSaved(showSaved)
        
    }
    private func resetSearchBar(){
        self.searchBar.isHidden = !showSaved
        self.searchBar.text = ""
        searchBarConstraint.constant = self.showSaved ? 44 : 0
        self.layoutIfNeeded()
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        self.subredditLabel.text = ""
        
    }
    
    func config(subreddit: String){
        print("config header")
        self.subredditLabel.text = subreddit
        self.searchBar.delegate = searchDelegate
    }
    private func updateButtonStyle(){
        let bookmarkImg = self.showSaved ? "bookmark.circle.fill" : "bookmark.circle"
        self.savedButton.setImage(UIImage(systemName: bookmarkImg), for: .normal)
    }
    func makeSearchBarFirstResponder() {
        self.searchBar.becomeFirstResponder()
    }
    
}
