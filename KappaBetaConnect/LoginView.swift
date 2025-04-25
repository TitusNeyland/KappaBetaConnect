import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Logo at the top
                Image("kblogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(.top, 50)
                
                // Login form
                VStack(spacing: 15) {
                    CustomTextField(text: $email, placeholder: "Email", keyboardType: .emailAddress, textContentType: .emailAddress)
                        .customTextField()
                    
                    ZStack(alignment: .trailing) {
                        if showPassword {
                            CustomTextField(text: $password, placeholder: "Password", isSecure: false)
                                .customTextField()
                        } else {
                            CustomTextField(text: $password, placeholder: "Password", isSecure: true)
                                .customTextField()
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
                    
                    Button(action: {
                        login()
                    }) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Logging in...")
                                    .foregroundColor(.white)
                                    .padding(.leading, 8)
                            }
                        } else {
                            Text("Login")
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
                    .disabled(isLoading)
                    .animation(.easeInOut, value: isLoading)
                    
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot Password?")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Updated sign up prompt with navigation
                HStack {
                    Text("Not a member?")
                        .foregroundColor(.gray)
                    NavigationLink("Sign Up", destination: SignUpView())
                        .foregroundColor(.black)
                        .fontWeight(.bold)
                }
                .padding(.bottom, 20)
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
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            if newValue {
                isLoading = false
                dismiss()
            }
        }
    }
    
    private func login() {
        isLoading = true
        
        // Validate input
        if email.isEmpty {
            showError(message: "Please enter your email")
            return
        }
        
        if password.isEmpty {
            showError(message: "Please enter your password")
            return
        }
        
        // Attempt to sign in
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                await MainActor.run {
                    showError(message: "Login failed: \(error.localizedDescription)")
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
        LoginView()
            .environmentObject(AuthManager())
    }
} 
