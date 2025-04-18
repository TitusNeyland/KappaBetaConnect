import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    var id: String?
    
    // Personal Information
    var prefix: String?
    var firstName: String
    var lastName: String
    var suffix: String?
    var email: String
    var phoneNumber: String
    var city: String?
    var state: String?
    
    // Security
    var password: String // Note: In a real app, passwords should not be stored directly. Firebase Auth handles this.
    
    // Profile Information
    var careerField: String?
    var major: String?
    var jobTitle: String?
    var company: String?
    var bio: String?
    var interests: [String]?
    
    // Initiation Information
    var lineNumber: String?
    var semester: String?
    var year: String?
    var status: String? // collegiate or alumni
    var graduationYear: String?
    
    // Additional Information
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    
    // Optional social info
    var profileImageURL: String?
    var linkedInURL: String?
    var instagramURL: String?
    var twitterURL: String?
    var snapchatURL: String?
    var facebookURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case prefix, firstName, lastName, suffix, email, phoneNumber, city, state
        case password
        case careerField, major, jobTitle, company, bio, interests
        case lineNumber, semester, year, status, graduationYear
        case createdAt, updatedAt, isActive
        case profileImageURL, linkedInURL, instagramURL, twitterURL, snapchatURL, facebookURL
    }
    
    init(id: String? = nil, 
         prefix: String? = nil, 
         firstName: String, 
         lastName: String, 
         suffix: String? = nil, 
         email: String, 
         phoneNumber: String,
         city: String? = nil,
         state: String? = nil,
         password: String,
         careerField: String? = nil, 
         major: String? = nil, 
         jobTitle: String? = nil, 
         company: String? = nil,
         bio: String? = nil,
         interests: [String]? = nil,
         lineNumber: String? = nil,
         semester: String? = nil,
         year: String? = nil,
         status: String? = nil,
         graduationYear: String? = nil,
         profileImageURL: String? = nil,
         linkedInURL: String? = nil,
         instagramURL: String? = nil,
         twitterURL: String? = nil,
         snapchatURL: String? = nil,
         facebookURL: String? = nil,
         isActive: Bool = true) {
        
        self.id = id
        self.prefix = prefix
        self.firstName = firstName
        self.lastName = lastName
        self.suffix = suffix
        self.email = email
        self.phoneNumber = phoneNumber
        self.city = city
        self.state = state
        self.password = password
        self.careerField = careerField
        self.major = major
        self.jobTitle = jobTitle
        self.company = company
        self.bio = bio
        self.interests = interests
        self.lineNumber = lineNumber
        self.semester = semester
        self.year = year
        self.status = status
        self.graduationYear = graduationYear
        self.profileImageURL = profileImageURL
        self.linkedInURL = linkedInURL
        self.instagramURL = instagramURL
        self.twitterURL = twitterURL
        self.snapchatURL = snapchatURL
        self.facebookURL = facebookURL
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isActive = isActive
    }
} 
