import SwiftUI

struct RequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .primary : .gray)
        }
    }
}

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
    
    // Password validation states
    @State private var hasMinLength = false
    @State private var hasUppercase = false
    @State private var hasLowercase = false
    @State private var hasNumber = false
    @State private var hasSpecialChar = false
    
    private var passwordStrength: Double {
        var strength = 0.0
        if hasMinLength { strength += 0.2 }
        if hasUppercase { strength += 0.2 }
        if hasLowercase { strength += 0.2 }
        if hasNumber { strength += 0.2 }
        if hasSpecialChar { strength += 0.2 }
        return strength
    }
    
    private var passwordStrengthColor: Color {
        switch passwordStrength {
            case 0.0..<0.4: return .red
            case 0.4..<0.8: return .orange
            default: return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.top, 30)
            
            ScrollView {
                VStack(spacing: 15) {
                    // Password requirements explanation
                    Text("Password must contain:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        RequirementRow(text: "At least 8 characters", isMet: hasMinLength)
                        RequirementRow(text: "At least one uppercase letter", isMet: hasUppercase)
                        RequirementRow(text: "At least one lowercase letter", isMet: hasLowercase)
                        RequirementRow(text: "At least one number", isMet: hasNumber)
                        RequirementRow(text: "At least one special character", isMet: hasSpecialChar)
                    }
                    .padding(.horizontal)
                    
                    // Password strength indicator
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password Strength")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 4)
                                
                                Rectangle()
                                    .fill(passwordStrengthColor)
                                    .frame(width: geometry.size.width * passwordStrength, height: 4)
                            }
                            .cornerRadius(2)
                        }
                        .frame(height: 4)
                    }
                    .padding(.horizontal)
                    
                    // Password Field
                    ZStack(alignment: .trailing) {
                        if showPassword {
                            CustomTextField(text: $password, placeholder: "Password", textContentType: .newPassword, isSecure: false)
                                .customTextField()
                                .onChange(of: password) { validatePassword($0) }
                        } else {
                            CustomTextField(text: $password, placeholder: "Password", textContentType: .newPassword, isSecure: true)
                                .customTextField()
                                .onChange(of: password) { validatePassword($0) }
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 20))
                                .frame(width: 44, height: 44)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 8)
                    }
                    
                    // Confirm Password Field
                    ZStack(alignment: .trailing) {
                        if showConfirmPassword {
                            CustomTextField(text: $confirmPassword, placeholder: "Confirm Password", textContentType: .newPassword, isSecure: false)
                                .customTextField()
                        } else {
                            CustomTextField(text: $confirmPassword, placeholder: "Confirm Password", textContentType: .newPassword, isSecure: true)
                                .customTextField()
                        }
                        
                        Button(action: {
                            showConfirmPassword.toggle()
                        }) {
                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 20))
                                .frame(width: 44, height: 44)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 8)
                    }
                    
                    Button(action: {
                        createAccount()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(passwordStrength == 1.0 ? Color.black : Color.gray)
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Complete Setup")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .padding(.horizontal, 30)
                    .contentShape(Rectangle())
                    .disabled(isLoading || passwordStrength < 1.0)
                }
                .padding(.horizontal, 30)
            }
            
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
    
    private func validatePassword(_ password: String) {
        hasMinLength = password.count >= 8
        hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        hasSpecialChar = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
    }
    
    private func createAccount() {
        isLoading = true
        
        // Validate passwords
        if password.isEmpty {
            showError(message: "Please enter a password")
            return
        }
        
        if passwordStrength < 1.0 {
            showError(message: "Please ensure your password meets all requirements")
            return
        }
        
        if password != confirmPassword {
            showError(message: "Passwords do not match")
            return
        }
        
        // Create user in Firebase
        Task {
            do {
                let user = userData.createUser()
                _ = try await authManager.signUp(email: userData.email, password: password, userData: user)
                
                // Update UI on main thread
                await MainActor.run {
                    isLoading = false
                    navigateToProfilePicture = true
                }
            } catch {
                await MainActor.run {
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