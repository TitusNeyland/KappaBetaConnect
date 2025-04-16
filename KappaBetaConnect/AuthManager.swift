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
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticated = user != nil
            self?.userId = user?.uid
            
            if let userId = user?.uid {
                Task {
                    do {
                        let user = try await self?.userRepository.getUser(withId: userId)
                        DispatchQueue.main.async {
                            self?.currentUser = user
                        }
                    } catch {
                        print("Error fetching user: \(error.localizedDescription)")
                    }
                }
            } else {
                self?.currentUser = nil
            }
        }
    }
    
    func signUp(email: String, password: String, userData: User) async throws -> String {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let userId = authResult.user.uid
        
        var user = userData
        user.id = userId
        
        try await userRepository.createUser(user)
        
        return userId
    }
    
    func signIn(email: String, password: String) async throws {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        let userId = authResult.user.uid
        
        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.userId = userId
        }
        
        if let user = try await userRepository.getUser(withId: userId) {
            DispatchQueue.main.async {
                self.currentUser = user
            }
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
    }
    
    func resetPassword(forEmail email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
} 