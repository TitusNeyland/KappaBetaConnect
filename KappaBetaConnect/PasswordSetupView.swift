import SwiftUI

struct PasswordSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserSignupData
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var navigateToProfilePicture = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.top, 30)
            
            ScrollView {
                VStack(spacing: 15) {
                    // Password Field
                    ZStack(alignment: .trailing) {
                        CustomTextField(text: $password, placeholder: "Password", textContentType: .newPassword, isSecure: !showPassword)
                            .customTextField()
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                    
                    // Confirm Password Field
                    ZStack(alignment: .trailing) {
                        CustomTextField(text: $confirmPassword, placeholder: "Confirm Password", textContentType: .newPassword, isSecure: !showConfirmPassword)
                            .customTextField()
                        
                        Button(action: {
                            showConfirmPassword.toggle()
                        }) {
                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                    
                    Button(action: {
                        createAccount()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Complete Setup")
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
                    .disabled(isLoading)
                }
                .padding(.horizontal, 30)
            }
            
            // Hidden NavigationLink for navigation to ProfilePicturePromptView
            NavigationLink(destination: ProfilePicturePromptView().navigationBarBackButtonHidden(true), isActive: $navigateToProfilePicture) {
                EmptyView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                        Text("Back")
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .toolbarColorScheme(.light, for: .navigationBar)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createAccount() {
        isLoading = true
        
        // Validate passwords
        if password.isEmpty {
            showError(message: "Please enter a password")
            return
        }
        
        if password.count < 6 {
            showError(message: "Password must be at least 6 characters")
            return
        }
        
        if password != confirmPassword {
            showError(message: "Passwords do not match")
            return
        }
        
        // Set password in userData
        userData.password = password
        
        // Create user in Firebase
        Task {
            do {
                let user = userData.createUser()
                _ = try await authManager.signUp(email: userData.email, password: password, userData: user)
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    isLoading = false
                    navigateToProfilePicture = true
                }
            } catch {
                DispatchQueue.main.async {
                    showError(message: "Failed to create account: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        PasswordSetupView(userData: UserSignupData())
            .environmentObject(AuthManager())
    }
} 