import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
class SignUpViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var userName = ""
    @Published var jobTitle = ""
    @Published var company = ""
    @Published var location = ""
    @Published var industry = ""
    @Published var yearsExperience = ""
    @Published var alumniStatus = ""
    @Published var initiationYear = ""
    @Published var lineName = ""
    @Published var lineNumber = ""
    @Published var shipName = ""
    @Published var positions: [String] = []
    @Published var skills: [String] = []
    @Published var interests: [String] = []
    @Published var bio = ""
    @Published var linkedin = ""
    @Published var instagram = ""
    @Published var twitter = ""
    @Published var snapchat = ""
    
    @Published var error: Error?
    @Published var isLoading = false
    @Published var isSignedUp = false
    
    private let userService = UserService()
    
    func signUp() async {
        guard validateInputs() else { return }
        
        isLoading = true
        
        do {
            // Create Firebase Auth user
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Create User object
            let user = User(
                id: authResult.user.uid,
                userName: userName,
                jobTitle: jobTitle,
                company: company,
                location: location,
                industry: industry,
                yearsExperience: yearsExperience,
                alumniStatus: alumniStatus,
                initiationYear: initiationYear,
                lineName: lineName,
                lineNumber: lineNumber,
                shipName: shipName,
                positions: positions,
                skills: skills,
                interests: interests,
                bio: bio,
                socialMedia: User.SocialMedia(
                    linkedin: linkedin,
                    instagram: instagram,
                    twitter: twitter,
                    snapchat: snapchat
                ),
                profileImageURL: nil
            )
            
            // Store user data in Firestore
            try await userService.createUser(user)
            
            isSignedUp = true
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    private func validateInputs() -> Bool {
        // Basic validation
        guard !email.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty,
              !userName.isEmpty,
              password == confirmPassword,
              password.count >= 6 else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please fill in all required fields and ensure passwords match"])
            return false
        }
        
        return true
    }
} 