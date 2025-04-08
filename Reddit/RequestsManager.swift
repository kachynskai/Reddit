//
//  RequestsManager.swift
//  Reddit
//
//  Created by Iryna on 10.03.2025.
//

import Foundation

enum Params: String, CaseIterable{
    case subreddit
    case limit
    case after
    
    static func isValid(_ name: String) -> Bool {
        return Params.allCases.contains { $0.rawValue == name }
    }
}

struct UrlBuilder{
    private var urlComponents: URLComponents
    
    init?(path: String){
        guard let urlComponents = URLComponents(string: path)else{return nil}
        self.urlComponents = urlComponents
    }
    
    mutating func addQueryItem(name: String, value: String?)throws{
        guard Params.isValid(name) else {throw PostError.invalidURL}
        if name == Params.subreddit.rawValue {
           try updatePath(with: value)
        } else {
            updateQueryItem(name: name, value: value)
        }
    }
    
    private mutating func updatePath(with subreddit: String?) throws{
        guard let subreddit = subreddit, !subreddit.isEmpty else {throw PostError.invalidURL}
        var pathComponents = urlComponents.path.split(separator: "/").map(String.init)

        if let subredditIndex = pathComponents.firstIndex(of: "r"), subredditIndex + 1 < pathComponents.count {
            pathComponents[subredditIndex + 1] = subreddit
        }
        urlComponents.path = "/" + pathComponents.joined(separator: "/")
    }
    
    private mutating func updateQueryItem(name: String, value: String?) {
        var items = urlComponents.queryItems ?? []
        items.removeAll { $0.name == name }
        items.append(URLQueryItem(name: name, value: value))
        urlComponents.queryItems = items
    }

        
    func getSubreddit() -> String? {
        let pathComponents = urlComponents.path.split(separator: "/")
        guard let subredditIndex = pathComponents.firstIndex(of: "r"), subredditIndex + 1 < pathComponents.count else {return nil}
        return "r/\(pathComponents[subredditIndex + 1])"
    }


    func buildUrl() -> URL? {
        urlComponents.url
    }
}

struct PostResponseData: Codable{
    let data: PostChildren
}

struct PostChildren: Codable{
    let after: String?
    let children:[PostGeneralInfo]
}

struct PostGeneralInfo: Codable{
    let data: PostData
}

struct PostData: Codable{
    let author_fullname: String
    let title: String
    let saved: Bool
    let downs: Int
    let ups: Int
    let domain: String
    let preview: PostPreview?
    let id: String
    let permalink: String
    let num_comments: Int
    let created_utc: Int
    
}
extension PostData{
    func getTimePassed() -> String{
        let now = Date()
        let creatingDate = Date(timeIntervalSince1970: TimeInterval(self.created_utc))
        let difference = now.timeIntervalSince(creatingDate)
        if difference < 3600 {
            return "\(Int(difference / 60))m"
        } else if difference < 86400 {
            return "\(Int(difference / 3600))h"
        } else {
            return "\(Int(difference / 86400))d"
        }
    }
}

struct PostPreview: Codable{
    let images: [PostImageSource]
}

struct PostImageSource: Codable{
    let source: PostImage
}

struct PostImage: Codable{
    let url:String
    
}
extension PostImage{
    func getCorrectImgURL()->String{
        self.url.replacingOccurrences(of: "&amp;", with: "&")
    }
}
struct Post: Codable{
    let userName: String
    let timePassed: String
    let domain: String
    let title: String
    let imgURL: String?
    let rating: Int
    let id: String
    let url:String
    let numComments: Int
    var saved: Bool
    
    init(from data: PostData) throws {
        
        if let img = data.preview?.images.first{
            self.imgURL = img.source.getCorrectImgURL()
        }else { self.imgURL = nil}
        
        self.userName = data.author_fullname
        self.domain = data.domain
        self.title = data.title
        self.saved = SavedPostManager.shared.isPostSaved(id: data.id)
        self.rating = data.ups + data.downs
        self.id = data.id
        self.url = "https://www.reddit.com\(data.permalink)"
        self.numComments = data.num_comments
        self.timePassed = data.getTimePassed()
        }
        
    static func from(responseData: PostResponseData) throws -> [Post] {
        print(responseData)
        return try responseData.data.children.map{ try Post(from: $0.data) }
    }
   
}
final class DataLoader{
    private var urlBuilder: UrlBuilder
    
    init(path: String) throws{
        guard let urlBuilder = UrlBuilder(path: path) else {throw PostError.invalidURL}
        self.urlBuilder = urlBuilder
    }
    
    func addParams(name: String, value: String?) throws{
        try urlBuilder.addQueryItem(name: name, value: value)
    }
    
    func getSubreddit() -> String?{
        urlBuilder.getSubreddit();
    }
    
    func getData()async throws -> ([Post], String?){
        guard let path = urlBuilder.buildUrl() else{throw PostError.invalidURL}
        print("PATHHH:\(path)\n")
        let result = try await fetchPost(from: path)
        let posts = try Post.from(responseData: result)
        let after = result.data.after
        return (posts, after)
    }
    
    private func fetchPost(from url: URL) async throws -> PostResponseData{
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200
        else{throw PostError.invalidResponse}
        do{
            return try JSONDecoder().decode(PostResponseData.self, from: data)
        }catch {
            throw PostError.INVALID
        }
    }
}

enum PostError: Error{
    case invalidURL
    case invalidResponse
    case invalidData
    case invalidImage
    case invalidPost
    case INVALID
}

final class SavedPostManager{
    static let shared = SavedPostManager()
    
    private let fileURL:  URL
    private let fileManager = FileManager.default
    
    private init(){
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documentsURL.appendingPathComponent("savedPosts.json")
    }
    func loadAll()->[Post]{
        guard let data = fileManager.contents(atPath: fileURL.path(percentEncoded: false)),
            let savedPosts = try? JSONDecoder().decode([Post].self, from: data) else {
            print("Empty posts file")
            return []
            }
        return savedPosts
    }
    private func saveInFile(_ posts: [Post]) {
        do {
            let data = try JSONEncoder().encode(posts)
            try data.write(to: fileURL)
            print("File updated")
        } catch {
            print("Problem with updating:  \(error.localizedDescription)")
        }
    }
    
    func toggle(post: Post){
        var posts = loadAll()
        if let idx = posts.firstIndex(where: {$0.id == post.id}){
            posts.remove(at: idx)
        }else{
            posts.append(post)
        }
        saveInFile(posts);
    }
    func isPostSaved(id: String) -> Bool{
        let posts = loadAll()
        return posts.contains(where: {$0.id == id})
    }
}
