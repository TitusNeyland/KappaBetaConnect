import Foundation
import FirebaseFirestore

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let description: String
    let date: Date
    let location: String
    let createdBy: String // User ID of the creator
    let createdAt: Date
    var attendees: [String] // Array of user IDs
    var isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case date
        case location
        case createdBy
        case createdAt
        case attendees
        case isActive
    }
} 
