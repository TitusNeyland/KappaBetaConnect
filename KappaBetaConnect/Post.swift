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
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case authorId
        case authorName
        case timestamp
        case likes
        case comments
        case shareCount
    }
}

struct Comment: Identifiable, Codable {
    var id: String?
    var content: String
    var authorId: String
    var authorName: String
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case authorId
        case authorName
        case timestamp
    }
} 