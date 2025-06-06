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
    var imageURLs: [String] // Array of image URLs, max 4
    
    init(content: String, authorId: String, authorName: String, timestamp: Date = Date(), likes: [String] = [], comments: [Comment] = [], shareCount: Int = 0, imageURLs: [String] = []) {
        self.content = content
        self.authorId = authorId
        self.authorName = authorName
        self.timestamp = timestamp
        self.likes = likes
        self.comments = comments
        self.shareCount = shareCount
        self.imageURLs = imageURLs
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case authorId
        case authorName
        case timestamp
        case likes
        case comments
        case shareCount
        case imageURLs
    }
}

struct Comment: Identifiable, Codable {
    var id: String?
    var content: String
    var authorId: String
    var authorName: String
    var timestamp: Date
    var mentions: [Mention]
    var imageURL: String? // Optional image URL for comments
    var replies: [Comment] // Nested replies
    var likes: [String] // User IDs who liked this comment
    
    init(id: String? = nil, content: String, authorId: String, authorName: String, timestamp: Date = Date(), mentions: [Mention] = [], imageURL: String? = nil, replies: [Comment] = [], likes: [String] = []) {
        self.id = id
        self.content = content
        self.authorId = authorId
        self.authorName = authorName
        self.timestamp = timestamp
        self.mentions = mentions
        self.imageURL = imageURL
        self.replies = replies
        self.likes = likes
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case authorId
        case authorName
        case timestamp
        case mentions
        case imageURL
        case replies
        case likes
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