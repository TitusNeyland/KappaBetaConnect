import Foundation
import FirebaseFirestore
import Combine

class UserRepository: ObservableObject {
    let db = Firestore.firestore()
    private let usersCollection = "users"
    
    @Published var currentUser: User?
    
    func createUser(_ user: User) async throws -> String {
        let docRef = db.collection(usersCollection).document()
        var userToSave = user
        userToSave.id = docRef.documentID
        
        // Convert user to dictionary
        let userData = try userToDictionary(userToSave)
        
        try await docRef.setData(userData)
        return docRef.documentID
    }
    
    func getUser(withId id: String) async throws -> User? {
        let docRef = db.collection(usersCollection).document(id)
        let document = try await docRef.getDocument()
        
        if document.exists, let data = document.data() {
            return try dictionaryToUser(data, id: id)
        }
        
        return nil
    }
    
    func getUserByEmail(_ email: String) async throws -> User? {
        let snapshot = try await db.collection(usersCollection)
            .whereField("email", isEqualTo: email)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return try dictionaryToUser(document.data(), id: document.documentID)
    }
    
    func updateUser(_ user: User) async throws {
        guard let userId = user.id else {
            throw NSError(domain: "UserRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "User has no ID"])
        }
        
        var updatedUser = user
        updatedUser.updatedAt = Date()
        
        // Convert user to dictionary
        let userData = try userToDictionary(updatedUser)
        
        let docRef = db.collection(usersCollection).document(userId)
        try await docRef.setData(userData)
    }
    
    func deleteUser(withId id: String) async throws {
        try await db.collection(usersCollection).document(id).delete()
    }
    
    func updateUserProfileImage(userId: String, imageURL: String) async throws {
        let docRef = db.collection(usersCollection).document(userId)
        try await docRef.updateData([
            "profileImageURL": imageURL,
            "updatedAt": Timestamp(date: Date())
        ])
    }
    
    func searchUsers(byName searchText: String) async throws -> [User] {
        if searchText.isEmpty {
            // If search is empty, return all users
            let snapshot = try await db.collection(usersCollection)
                .getDocuments()
            
            return try snapshot.documents.compactMap { document in
                try? dictionaryToUser(document.data(), id: document.documentID)
            }
        }
        
        let searchText = searchText.lowercased()
        
        // Get all users and filter them in memory
        let snapshot = try await db.collection(usersCollection)
            .getDocuments()
        
        let allUsers = try snapshot.documents.compactMap { document in
            try? dictionaryToUser(document.data(), id: document.documentID)
        }
        
        // Filter users based on partial matches in first name or last name
        return allUsers.filter { user in
            let firstName = user.firstName.lowercased()
            let lastName = user.lastName.lowercased()
            
            return firstName.contains(searchText) || lastName.contains(searchText)
        }
    }
    
    // Helper function to convert User to Firestore dictionary
    private func userToDictionary(_ user: User) throws -> [String: Any] {
        let dateFormatter = ISO8601DateFormatter()
        
        var dict: [String: Any] = [
            "firstName": user.firstName,
            "lastName": user.lastName,
            "email": user.email,
            "phoneNumber": user.phoneNumber,
            "password": user.password,
            "createdAt": Timestamp(date: user.createdAt),
            "updatedAt": Timestamp(date: user.updatedAt),
            "isActive": user.isActive
        ]
        
        // Add optional fields if they have values
        if let prefix = user.prefix { dict["prefix"] = prefix }
        if let suffix = user.suffix { dict["suffix"] = suffix }
        if let careerField = user.careerField { dict["careerField"] = careerField }
        if let major = user.major { dict["major"] = major }
        if let jobTitle = user.jobTitle { dict["jobTitle"] = jobTitle }
        if let company = user.company { dict["company"] = company }
        if let profileImageURL = user.profileImageURL { dict["profileImageURL"] = profileImageURL }
        if let linkedInURL = user.linkedInURL { dict["linkedInURL"] = linkedInURL }
        if let lineNumber = user.lineNumber { dict["lineNumber"] = lineNumber }
        if let semester = user.semester { dict["semester"] = semester }
        if let year = user.year { dict["year"] = year }
        
        return dict
    }
    
    // Helper function to convert Firestore dictionary to User
    func dictionaryToUser(_ dict: [String: Any], id: String) throws -> User {
        guard let firstName = dict["firstName"] as? String,
              let lastName = dict["lastName"] as? String,
              let email = dict["email"] as? String,
              let phoneNumber = dict["phoneNumber"] as? String,
              let password = dict["password"] as? String,
              let isActive = dict["isActive"] as? Bool else {
            throw NSError(domain: "UserRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid user data"])
        }
        
        // Convert Firestore timestamps to Date
        let createdAt = (dict["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (dict["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        
        return User(
            id: id,
            prefix: dict["prefix"] as? String,
            firstName: firstName,
            lastName: lastName,
            suffix: dict["suffix"] as? String,
            email: email,
            phoneNumber: phoneNumber,
            password: password,
            careerField: dict["careerField"] as? String,
            major: dict["major"] as? String,
            jobTitle: dict["jobTitle"] as? String,
            company: dict["company"] as? String,
            lineNumber: dict["lineNumber"] as? String,
            semester: dict["semester"] as? String,
            year: dict["year"] as? String,
            profileImageURL: dict["profileImageURL"] as? String,
            linkedInURL: dict["linkedInURL"] as? String,
            isActive: isActive
        )
    }
} 