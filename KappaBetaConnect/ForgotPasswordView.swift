import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Logo at the top
                Image("kblogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(.top, 50)
                
                // Forgot password form
                VStack(spacing: 15) {
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                    
                    CustomTextField(text: $email, placeholder: "Email", keyboardType: .emailAddress, textContentType: .emailAddress)
                        .customTextField()
                    
                    Button(action: {
                        resetPassword()
                    }) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Sending...")
                                    .foregroundColor(.white)
                                    .padding(.leading, 8)
                            }
                        } else {
                            Text("Send Reset Link")
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
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Password reset email sent. Please check your inbox.")
        }
    }
    
    private func resetPassword() {
        isLoading = true
        
        // Validate input
        if email.isEmpty {
            showError(message: "Please enter your email")
            return
        }
        
        if !isValidEmail(email) {
            showError(message: "Please enter a valid email address")
            return
        }
        
        // Attempt to reset password
        Task {
            do {
                try await authManager.resetPassword(forEmail: email)
                await MainActor.run {
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    showError(message: "Failed to send reset email: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        isLoading = false
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environmentObject(AuthManager())
    }
} 