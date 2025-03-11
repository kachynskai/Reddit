//
//  PostViewController.swift
//  Reddit
//
//  Created by Iryna on 10.03.2025.
//

import UIKit

class PostViewController: UIViewController {
    private var dataLoader: DataLoader?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
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
        try dataLoader?.addParams(name: "limit", value: "1")
        
        let post = try await dataLoader?.getData()
        print("📌 Отриманий пост: \(String(describing: post))")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
