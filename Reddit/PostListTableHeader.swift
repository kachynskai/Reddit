//
//  PostListTableHeader.swift
//  Reddit
//
//  Created by Iryna on 07.04.2025.
//
import UIKit

class PostListTableHeader: UITableViewCell{
    @IBOutlet private weak var subredditLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.subredditLabel.text = ""
        
    }
    
    func config(subreddit: String){
        print("config header")
        self.subredditLabel.text = subreddit
    }
    
}
