import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class UserService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Create
    func createUser(_ user: User) async throws {
        let documentRef = db.collection("users").document(user.id)
        try documentRef.setData(from: user)
    }
    
    // MARK: - Read
    func getUser(id: String) async throws -> User {
        let document = try await db.collection("users").document(id).getDocument()
        return try document.data(as: User.self)
    }
    
    func getAllUsers() async throws -> [User] {
        let snapshot = try await db.collection("users").getDocuments()
        return try snapshot.documents.compactMap { document in
            try document.data(as: User.self)
        }
    }
    
    // MARK: - Update
    func updateUser(_ user: User) async throws {
        let documentRef = db.collection("users").document(user.id)
        try documentRef.setData(from: user, merge: true)
    }
    
    // MARK: - Delete
    func deleteUser(id: String) async throws {
        try await db.collection("users").document(id).delete()
    }
    
    // MARK: - Search
    func searchUsers(query: String) async throws -> [User] {
        let snapshot = try await db.collection("users")
            .whereField("userName", isGreaterThanOrEqualTo: query)
            .whereField("userName", isLessThanOrEqualTo: query + "\u{f8ff}")
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: User.self)
        }
    }
} 