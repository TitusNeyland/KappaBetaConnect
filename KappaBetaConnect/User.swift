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
    
    // Security
    var password: String // Note: In a real app, passwords should not be stored directly. Firebase Auth handles this.
    
    // Profile Information
    var careerField: String?
    var major: String?
    var jobTitle: String?
    var company: String?
    
    // Additional Information
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    
    // Optional social info
    var profileImageURL: String?
    var linkedInURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case prefix, firstName, lastName, suffix, email, phoneNumber
        case password
        case careerField, major, jobTitle, company
        case createdAt, updatedAt, isActive
        case profileImageURL, linkedInURL
    }
    
    init(id: String? = nil, 
         prefix: String? = nil, 
         firstName: String, 
         lastName: String, 
         suffix: String? = nil, 
         email: String, 
         phoneNumber: String, 
         password: String,
         careerField: String? = nil, 
         major: String? = nil, 
         jobTitle: String? = nil, 
         company: String? = nil,
         profileImageURL: String? = nil,
         linkedInURL: String? = nil,
         isActive: Bool = true) {
        
        self.id = id
        self.prefix = prefix
        self.firstName = firstName
        self.lastName = lastName
        self.suffix = suffix
        self.email = email
        self.phoneNumber = phoneNumber
        self.password = password
        self.careerField = careerField
        self.major = major
        self.jobTitle = jobTitle
        self.company = company
        self.profileImageURL = profileImageURL
        self.linkedInURL = linkedInURL
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isActive = isActive
    }
} 