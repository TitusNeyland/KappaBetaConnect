import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo at the top
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.top, 50)
            
            // Login form
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .customTextField()
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                ZStack(alignment: .trailing) {
                    if showPassword {
                        TextField("Password", text: $password)
                            .customTextField()
                    } else {
                        SecureField("Password", text: $password)
                            .customTextField()
                    }
                    
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
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
                
                Button("Forgot Password?") {
                    // Handle forgot password action
                }
                .foregroundColor(.gray)
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
        .background(Color(.systemBackground))
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
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
                
                // Auth state listener in AuthManager will update isAuthenticated
                // and navigate to MainTabView via ContentView
                DispatchQueue.main.async {
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
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
