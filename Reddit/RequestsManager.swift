//
//  RequestsManager.swift
//  Reddit
//
//  Created by Iryna on 10.03.2025.
//

import Foundation

enum Params: String{
    case subreddit
    case limit
    case after
}

struct UrlBuilder{
    //тут не забути подумати про те, що можуть додавати однакові параметри, коли розберусь з їх зміною
    private var urlComponents: URLComponents
    
    init?(path: String){
        guard let urlComponents = URLComponents(string: path)else{return nil}
        self.urlComponents = urlComponents
    }
    
    mutating func addQueryItem(name: String, value: String?) {
        var items = urlComponents.queryItems ?? []
        items.append(URLQueryItem(name: name, value: value))
        urlComponents.queryItems = items
    }
    
    func buildUrl() -> URL? {
        urlComponents.url
    }
}

struct PostResponseData: Codable{
    let data: PostChildren
}

struct PostChildren: Codable{
    let children:[PostGeneralInfo]
}

struct PostGeneralInfo: Codable{
    let data: PostData
}

struct PostData: Codable{
    let author_fullname: String
    let title: String
    let downs: Int
    let ups: Int
    let domain: String
    let preview: PostPreview
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
struct Post{
    let userName: String
    let timePassed: String
    let domain: String
    let title: String
    let imgURL: String
    let rating: Int
    let numComments: Int
    var saved = Bool.random()
    
    init(from data: PostResponseData)throws{
        guard let post = data.data.children.first else {throw PostError.invalidData}
        guard let img = post.data.preview.images.first else{throw PostError.invalidImage}
        self.userName = post.data.author_fullname
        self.domain = post.data.domain
        self.title = post.data.title
        self.rating = post.data.ups + post.data.downs
        self.numComments = post.data.num_comments
        self.imgURL = img.source.getCorrectImgURL()
        self.timePassed = post.data.getTimePassed()
    }
   
}
final class DataLoader{
    private var urlBuilder: UrlBuilder
    
    init(path: String) throws{
        guard let urlBuilder = UrlBuilder(path: path) else {throw PostError.invalidURL}
        self.urlBuilder = urlBuilder
        print("loader was created")
    }
    
    func addParams(name: String, value: String?) throws{
        urlBuilder.addQueryItem(name: name, value: value)
    }
    
    func getData()async throws -> Post{
        guard let path = urlBuilder.buildUrl() else{throw PostError.invalidURL}
        let result = try await fetchPost(from: path)
        print("got result of request")
        return try Post(from: result)
    }
    
    private func fetchPost(from url: URL) async throws -> PostResponseData{
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else{throw PostError.invalidResponse}
        do{
            print("trying to decode")
            return try JSONDecoder().decode(PostResponseData.self, from: data)
        }catch {
            throw PostError.invalidData
        }
    }
}

enum PostError: Error{
    case invalidURL
    case invalidResponse
    case invalidData
    case invalidImage
    case gettingPostError
}
