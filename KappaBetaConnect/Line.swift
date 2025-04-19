import Foundation
import FirebaseFirestore

struct Line: Codable, Identifiable {
    var id: String?
    var line_name: String
    var semester: String
    var year: Int
    var members: [LineMember]
    
    enum CodingKeys: String, CodingKey {
        case id
        case line_name
        case semester
        case year
        case members
    }
}

struct LineMember: Codable, Identifiable {
    var id: String?
    var name: String
    var alias: String?
    var number: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case alias
        case number
    }
} 