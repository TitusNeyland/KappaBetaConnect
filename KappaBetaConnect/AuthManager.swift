import Foundation
import FirebaseAuth
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var userId: String?
    
    private var userRepository = UserRepository()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
        
        // Check current auth state
        if let user = Auth.auth().currentUser {
            self.isAuthenticated = true
            self.userId = user.uid
            
            Task {
                if let userData = try? await userRepository.getUser(withId: user.uid) {
                    await MainActor.run {
                        self.currentUser = userData
                    }
                }
            }
        }
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                self?.userId = user?.uid
                
                if let userId = user?.uid {
                    do {
                        if let user = try await self?.userRepository.getUser(withId: userId) {
                            self?.currentUser = user
                        }
                    } catch {
                        print("Error fetching user: \(error.localizedDescription)")
                    }
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
    
    func signUp(email: String, password: String, userData: User) async throws -> String {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let userId = authResult.user.uid
        
        var user = userData
        user.id = userId
        
        try await userRepository.createUser(user)
        
        await MainActor.run {
            self.isAuthenticated = true
            self.userId = userId
            self.currentUser = user
        }
        
        return userId
    }
    
    func signIn(email: String, password: String) async throws {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let userId = authResult.user.uid
        
        let user = try await userRepository.getUser(withId: userId)
        
        await MainActor.run {
            self.isAuthenticated = true
            self.userId = userId
            self.currentUser = user
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        
        Task { @MainActor in
            self.isAuthenticated = false
            self.currentUser = nil
            self.userId = nil
        }
    }
    
    func resetPassword(forEmail email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func updateEmail(to newEmail: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in"])
        }
        
        // First send a verification email to the new address
        try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
    }
} 