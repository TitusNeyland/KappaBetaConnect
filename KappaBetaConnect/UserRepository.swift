import Foundation
import FirebaseFirestore
import Combine
import FirebaseAuth

class ProfileImageCache {
    static let shared = ProfileImageCache()
    private var cache: [String: String] = [:]
    private let queue = DispatchQueue(label: "com.kappabeta.profileimagecache")
    
    func getProfileImage(for userId: String) -> String? {
        queue.sync {
            return cache[userId]
        }
    }
    
    func setProfileImage(for userId: String, url: String) {
        queue.async {
            self.cache[userId] = url
        }
    }
    
    func clearCache() {
        queue.async {
            self.cache.removeAll()
        }
    }
}

class UserRepository: ObservableObject {
    let db = Firestore.firestore()
    private let usersCollection = "users"
    
    @Published var currentUser: User?
    
    init() {
        //print("UserRepository initialized")
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            //print("Auth state changed. User ID: \(user?.uid ?? "nil")")
            if let user = user {
                Task {
                    do {
                        try await self?.fetchCurrentUser(userId: user.uid)
                        //print("Successfully fetched current user")
                    } catch {
                        print("Error fetching current user: \(error)")
                    }
                }
            } else {
                print("No user logged in")
                Task { @MainActor in
                    self?.currentUser = nil
                }
            }
        }
        
        // Check initial auth state
        if let currentUser = Auth.auth().currentUser {
           // print("Initial auth state - User ID: \(currentUser.uid)")
            Task {
                do {
                    try await fetchCurrentUser(userId: currentUser.uid)
                    //print("Successfully fetched initial current user")
                } catch {
                    print("Error fetching initial current user: \(error)")
                }
            }
        } else {
            print("Initial auth state - No user logged in")
        }
    }
    
    private func fetchCurrentUser(userId: String) async throws {
        //print("Fetching user with ID: \(userId)")
        if let user = try await getUser(withId: userId) {
            //print("Found user: \(user.firstName) \(user.lastName)")
            await MainActor.run {
                self.currentUser = user
                //print("Current user set to: \(user.firstName) \(user.lastName)")
            }
        } else {
            print("No user found with ID: \(userId)")
        }
    }
    
    func createUser(_ user: User) async throws -> String {
        guard let userId = user.id else {
            throw NSError(domain: "UserRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "User has no ID"])
        }
        
        let docRef = db.collection(usersCollection).document(userId)
        var userToSave = user
        
        // Convert user to dictionary
        let userData = try userToDictionary(userToSave)
        
        try await docRef.setData(userData)
        return userId
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
        
        // Update the currentUser property on the main thread
        await MainActor.run {
            if self.currentUser?.id == userId {
                self.currentUser = updatedUser
            }
        }
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
    
    func findUserByName(firstName: String, lastName: String) async throws -> User? {
        let snapshot = try await db.collection("users")
            .whereField("firstName", isEqualTo: firstName)
            .whereField("lastName", isEqualTo: lastName)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        var user = try document.data(as: User.self)
        user.id = document.documentID
        return user
    }
    
    // Helper function to convert User to Firestore dictionary
    private func userToDictionary(_ user: User) throws -> [String: Any] {
        let dateFormatter = ISO8601DateFormatter()
        
        var dict: [String: Any] = [
            "firstName": user.firstName,
            "lastName": user.lastName,
            "email": user.email,
            "phoneNumber": user.phoneNumber,
            "birthday": Timestamp(date: user.birthday),
            "createdAt": Timestamp(date: user.createdAt),
            "updatedAt": Timestamp(date: user.updatedAt),
            "isActive": user.isActive,
            "isFirstSignIn": user.isFirstSignIn,
            "isAdmin": user.isAdmin
        ]
        
        // Add optional fields if they have values
        if let prefix = user.prefix { dict["prefix"] = prefix }
        if let suffix = user.suffix { dict["suffix"] = suffix }
        if let city = user.city { dict["city"] = city }
        if let state = user.state { dict["state"] = state }
        if let homeCity = user.homeCity { dict["homeCity"] = homeCity }
        if let homeState = user.homeState { dict["homeState"] = homeState }
        if let careerField = user.careerField { dict["careerField"] = careerField }
        if let major = user.major { dict["major"] = major }
        if let jobTitle = user.jobTitle { dict["jobTitle"] = jobTitle }
        if let company = user.company { dict["company"] = company }
        if let bio = user.bio { dict["bio"] = bio }
        if let interests = user.interests { dict["interests"] = interests }
        if let profileImageURL = user.profileImageURL { dict["profileImageURL"] = profileImageURL }
        if let linkedInURL = user.linkedInURL { dict["linkedInURL"] = linkedInURL }
        if let instagramURL = user.instagramURL { dict["instagramURL"] = instagramURL }
        if let twitterURL = user.twitterURL { dict["twitterURL"] = twitterURL }
        if let snapchatURL = user.snapchatURL { dict["snapchatURL"] = snapchatURL }
        if let facebookURL = user.facebookURL { dict["facebookURL"] = facebookURL }
        if let lineNumber = user.lineNumber { dict["lineNumber"] = lineNumber }
        if let semester = user.semester { dict["semester"] = semester }
        if let year = user.year { dict["year"] = year }
        if let status = user.status { dict["status"] = status }
        if let graduationYear = user.graduationYear { dict["graduationYear"] = graduationYear }
        if let yearsOfExperience = user.yearsOfExperience { dict["yearsOfExperience"] = yearsOfExperience }
        
        return dict
    }
    
    // Helper function to convert Firestore dictionary to User
    func dictionaryToUser(_ dict: [String: Any], id: String) throws -> User {
        guard let firstName = dict["firstName"] as? String,
              let lastName = dict["lastName"] as? String,
              let email = dict["email"] as? String,
              let phoneNumber = dict["phoneNumber"] as? String,
              let birthday = (dict["birthday"] as? Timestamp)?.dateValue(),
              let isActive = dict["isActive"] as? Bool else {
            throw NSError(domain: "UserRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid user data"])
        }
        
        // Convert Firestore timestamps to Date
        let createdAt = (dict["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let updatedAt = (dict["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        
        let isFirstSignIn = dict["isFirstSignIn"] as? Bool ?? false
        let isAdmin = dict["isAdmin"] as? Bool ?? false
        
        let prefix = dict["prefix"] as? String
        let suffix = dict["suffix"] as? String
        let city = dict["city"] as? String
        let state = dict["state"] as? String
        let homeCity = dict["homeCity"] as? String
        let homeState = dict["homeState"] as? String
        let careerField = dict["careerField"] as? String
        let major = dict["major"] as? String
        let jobTitle = dict["jobTitle"] as? String
        let company = dict["company"] as? String
        let bio = dict["bio"] as? String
        let lineNumber = dict["lineNumber"] as? String
        let semester = dict["semester"] as? String
        let year = dict["year"] as? String
        let status = dict["status"] as? String
        let graduationYear = dict["graduationYear"] as? String
        let profileImageURL = dict["profileImageURL"] as? String
        let linkedInURL = dict["linkedInURL"] as? String
        let instagramURL = dict["instagramURL"] as? String
        let twitterURL = dict["twitterURL"] as? String
        let snapchatURL = dict["snapchatURL"] as? String
        let facebookURL = dict["facebookURL"] as? String
        
        var user = User(
            id: id,
            prefix: prefix,
            firstName: firstName,
            lastName: lastName,
            suffix: suffix,
            email: email,
            phoneNumber: phoneNumber,
            city: city,
            state: state,
            homeCity: homeCity,
            homeState: homeState,
            birthday: birthday,
            careerField: careerField,
            major: major,
            jobTitle: jobTitle,
            company: company,
            bio: bio,
            interests: dict["interests"] as? [String] ?? [],
            lineNumber: lineNumber,
            semester: semester,
            year: year,
            status: status,
            graduationYear: graduationYear,
            profileImageURL: profileImageURL,
            linkedInURL: linkedInURL,
            instagramURL: instagramURL,
            twitterURL: twitterURL,
            snapchatURL: snapchatURL,
            facebookURL: facebookURL,
            isActive: isActive,
            yearsOfExperience: dict["yearsOfExperience"] as? String ?? "",
            isFirstSignIn: isFirstSignIn,
            isAdmin: isAdmin
        )
        
        user.createdAt = createdAt
        user.updatedAt = updatedAt
        
        return user
    }
    
    func toFirestoreData(user: User) -> [String: Any] {
        var data: [String: Any] = [
            "firstName": user.firstName,
            "lastName": user.lastName,
            "email": user.email,
            "phoneNumber": user.phoneNumber,
            "birthday": user.birthday,
            "createdAt": user.createdAt,
            "updatedAt": user.updatedAt,
            "isActive": user.isActive,
            "isFirstSignIn": user.isFirstSignIn
        ]
        
        // Optional fields
        if let prefix = user.prefix { data["prefix"] = prefix }
        if let suffix = user.suffix { data["suffix"] = suffix }
        if let city = user.city { data["city"] = city }
        if let state = user.state { data["state"] = state }
        if let homeCity = user.homeCity { data["homeCity"] = homeCity }
        if let homeState = user.homeState { data["homeState"] = homeState }
        if let careerField = user.careerField { data["careerField"] = careerField }
        if let major = user.major { data["major"] = major }
        if let jobTitle = user.jobTitle { data["jobTitle"] = jobTitle }
        if let company = user.company { data["company"] = company }
        if let bio = user.bio { data["bio"] = bio }
        if let lineNumber = user.lineNumber { data["lineNumber"] = lineNumber }
        if let semester = user.semester { data["semester"] = semester }
        if let year = user.year { data["year"] = year }
        if let status = user.status { data["status"] = status }
        if let graduationYear = user.graduationYear { data["graduationYear"] = graduationYear }
        if let profileImageURL = user.profileImageURL { data["profileImageURL"] = profileImageURL }
        if let linkedInURL = user.linkedInURL { data["linkedInURL"] = linkedInURL }
        if let instagramURL = user.instagramURL { data["instagramURL"] = instagramURL }
        if let twitterURL = user.twitterURL { data["twitterURL"] = twitterURL }
        if let snapchatURL = user.snapchatURL { data["snapchatURL"] = snapchatURL }
        if let facebookURL = user.facebookURL { data["facebookURL"] = facebookURL }
        
        return data
    }
    
    func fromFirestoreData(_ data: [String: Any], id: String) -> User? {
        guard let firstName = data["firstName"] as? String,
              let lastName = data["lastName"] as? String,
              let email = data["email"] as? String,
              let phoneNumber = data["phoneNumber"] as? String,
              let birthday = (data["birthday"] as? Timestamp)?.dateValue(),
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
              let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue(),
              let isActive = data["isActive"] as? Bool else {
            return nil
        }
        
        let isFirstSignIn = data["isFirstSignIn"] as? Bool ?? false
        
        let prefix = data["prefix"] as? String
        let suffix = data["suffix"] as? String
        let city = data["city"] as? String
        let state = data["state"] as? String
        let homeCity = data["homeCity"] as? String
        let homeState = data["homeState"] as? String
        let careerField = data["careerField"] as? String
        let major = data["major"] as? String
        let jobTitle = data["jobTitle"] as? String
        let company = data["company"] as? String
        let bio = data["bio"] as? String
        let lineNumber = data["lineNumber"] as? String
        let semester = data["semester"] as? String
        let year = data["year"] as? String
        let status = data["status"] as? String
        let graduationYear = data["graduationYear"] as? String
        let profileImageURL = data["profileImageURL"] as? String
        let linkedInURL = data["linkedInURL"] as? String
        let instagramURL = data["instagramURL"] as? String
        let twitterURL = data["twitterURL"] as? String
        let snapchatURL = data["snapchatURL"] as? String
        let facebookURL = data["facebookURL"] as? String
        
        var user = User(
            id: id,
            prefix: prefix,
            firstName: firstName,
            lastName: lastName,
            suffix: suffix,
            email: email,
            phoneNumber: phoneNumber,
            city: city,
            state: state,
            homeCity: homeCity,
            homeState: homeState,
            birthday: birthday,
            careerField: careerField,
            major: major,
            jobTitle: jobTitle,
            company: company,
            bio: bio,
            interests: [],
            lineNumber: lineNumber,
            semester: semester,
            year: year,
            status: status,
            graduationYear: graduationYear,
            profileImageURL: profileImageURL,
            linkedInURL: linkedInURL,
            instagramURL: instagramURL,
            twitterURL: twitterURL,
            snapchatURL: snapchatURL,
            facebookURL: facebookURL,
            isActive: isActive,
            yearsOfExperience: "",
            isFirstSignIn: isFirstSignIn
        )
        
        user.createdAt = createdAt
        user.updatedAt = updatedAt
        
        return user
    }
    
    func getAllUsers() async throws -> [User] {
        let snapshot = try await db.collection(usersCollection).getDocuments()
        return try snapshot.documents.compactMap { document in
            try? dictionaryToUser(document.data(), id: document.documentID)
        }
    }
    
    func markFirstSignInComplete(forUser userId: String) async throws {
        let docRef = db.collection(usersCollection).document(userId)
        try await docRef.updateData([
            "isFirstSignIn": false,
            "updatedAt": Date()
        ])
    }
} 
