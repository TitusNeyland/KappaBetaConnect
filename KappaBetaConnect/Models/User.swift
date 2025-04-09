import Foundation

struct User: Identifiable, Codable {
    let id: String
    let userName: String
    let jobTitle: String
    let company: String
    let location: String
    let industry: String
    let yearsExperience: String
    let alumniStatus: String
    let initiationYear: String
    let lineName: String
    let lineNumber: String
    let shipName: String
    let positions: [String]
    let skills: [String]
    let interests: [String]
    let bio: String
    let socialMedia: SocialMedia
    let profileImageURL: URL?
    
    struct SocialMedia: Codable {
        let linkedin: String
        let instagram: String
        let twitter: String
        let snapchat: String
    }
}

// MARK: - Sample Data
extension User {
    static let sampleUser = User(
        id: UUID().uuidString,
        userName: "Titus Neyland",
        jobTitle: "Software Engineer",
        company: "Dillard's Inc.",
        location: "Little Rock, AR",
        industry: "Technology",
        yearsExperience: "5 years",
        alumniStatus: "Alumni",
        initiationYear: "2021",
        lineName: "INDEUCED IN2ENT",
        lineNumber: "2",
        shipName: "12 INVADERS",
        positions: ["Assistant Secretary"],
        skills: ["iOS Development", "Swift", "SwiftUI", "UI/UX Design", "Project Management"],
        interests: ["Technology", "Gaming", "Art", "Travel"],
        bio: "Passionate software engineer with a focus on iOS development. Creating innovative solutions and mentoring junior developers. Always excited to learn new technologies and contribute to meaningful projects.",
        socialMedia: SocialMedia(
            linkedin: "linkedin.com/in/titusneyland",
            instagram: "@username",
            twitter: "@username",
            snapchat: "@username"
        ),
        profileImageURL: nil
    )
} 