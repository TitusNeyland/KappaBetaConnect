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
    var homeCity: String?
    var homeState: String?
    var birthday: Date
    
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
    var isFirstSignIn: Bool
    var isAdmin: Bool
    
    // Optional social info
    var profileImageURL: String?
    var linkedInURL: String?
    var instagramURL: String?
    var twitterURL: String?
    var snapchatURL: String?
    var facebookURL: String?
    
    // New field
    var yearsOfExperience: String?
    
    // Terms and Safety
    var hasAgreedToTerms: Bool
    var blockedUsers: [String]
    var reportedContent: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case prefix, firstName, lastName, suffix, email, phoneNumber, city, state, homeCity, homeState
        case birthday
        case careerField, major, jobTitle, company, bio, interests
        case lineNumber, semester, year, status, graduationYear
        case createdAt, updatedAt, isActive, isFirstSignIn, isAdmin
        case profileImageURL, linkedInURL, instagramURL, twitterURL, snapchatURL, facebookURL
        case yearsOfExperience
        case hasAgreedToTerms, blockedUsers, reportedContent
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
         homeCity: String? = nil,
         homeState: String? = nil,
         birthday: Date = Date(),
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
         isActive: Bool = true,
         yearsOfExperience: String? = nil,
         isFirstSignIn: Bool = true,
         isAdmin: Bool = false,
         hasAgreedToTerms: Bool = false,
         blockedUsers: [String] = [],
         reportedContent: [String] = []) {
        
        self.id = id
        self.prefix = prefix
        self.firstName = firstName
        self.lastName = lastName
        self.suffix = suffix
        self.email = email
        self.phoneNumber = phoneNumber
        self.city = city
        self.state = state
        self.homeCity = homeCity
        self.homeState = homeState
        self.birthday = birthday
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
        self.isFirstSignIn = isFirstSignIn
        self.isAdmin = isAdmin
        self.yearsOfExperience = yearsOfExperience
        self.hasAgreedToTerms = hasAgreedToTerms
        self.blockedUsers = blockedUsers
        self.reportedContent = reportedContent
    }
} 
