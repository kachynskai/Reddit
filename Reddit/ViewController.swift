//
//  ViewController.swift
//  Reddit
//
//  Created by Iryna on 10.03.2025.
//

import UIKit

class ViewController: UIViewController {
    private var dataLoader: DataLoader?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        let builder = UrlBuilder(path: "https://www.reddit.com/r/ios/top.json?limit=1")!
        Task {
            do {
                try await fetchPost()
            } catch {
                print("Помилка завантаження: \(error)")
            }
        }
    }
    private func fetchPost() async throws {
        dataLoader = try DataLoader(path: "https://www.reddit.com/r/ios/top.json")
        try dataLoader?.addParams(name: "limit", value: "2")
        
        let post = try await dataLoader?.getData()
        print("Current post: \(String(describing: post))")
    }

}

