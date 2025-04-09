import Foundation
import SwiftUI

@MainActor
class UserViewModel: ObservableObject {
    private let userService = UserService()
    
    @Published var currentUser: User?
    @Published var users: [User] = []
    @Published var error: Error?
    @Published var isLoading = false
    
    // MARK: - User Operations
    func createUser(_ user: User) {
        isLoading = true
        Task {
            do {
                try await userService.createUser(user)
                currentUser = user
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func fetchUser(id: String) {
        isLoading = true
        Task {
            do {
                currentUser = try await userService.getUser(id: id)
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func fetchAllUsers() {
        isLoading = true
        Task {
            do {
                users = try await userService.getAllUsers()
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func updateUser(_ user: User) {
        isLoading = true
        Task {
            do {
                try await userService.updateUser(user)
                if currentUser?.id == user.id {
                    currentUser = user
                }
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func deleteUser(id: String) {
        isLoading = true
        Task {
            do {
                try await userService.deleteUser(id: id)
                users.removeAll { $0.id == id }
                if currentUser?.id == id {
                    currentUser = nil
                }
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    func searchUsers(query: String) {
        isLoading = true
        Task {
            do {
                users = try await userService.searchUsers(query: query)
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
} 