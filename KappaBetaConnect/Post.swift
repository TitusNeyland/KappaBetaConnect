import Foundation
import FirebaseFirestore

struct Post: Identifiable, Codable {
    var id: String?
    var content: String
    var authorId: String
    var authorName: String
    var timestamp: Date
    var likes: [String] // Array of user IDs who liked the post
    var comments: [Comment]
    var shareCount: Int
    var imageURL: String? // Optional image URL
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case authorId
        case authorName
        case timestamp
        case likes
        case comments
        case shareCount
        case imageURL
    }
}

struct Comment: Identifiable, Codable {
    var id: String?
    var content: String
    var authorId: String
    var authorName: String
    var timestamp: Date
    var mentions: [Mention] = []
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case authorId
        case authorName
        case timestamp
        case mentions
    }
}

struct Mention: Identifiable, Codable {
    var id: String
    var userId: String
    var userName: String
    var range: Range<Int>
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case userName
        case range
    }
} 