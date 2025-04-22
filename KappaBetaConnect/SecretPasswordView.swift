import SwiftUI
import CryptoKit

struct SecretPasswordView: View {
    @ObservedObject var userData: UserSignupData
    @State private var secretPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToPassword = false
    @State private var isLoading = false
    
    // Store the hashed password instead of the plain text
    private let hashedPassword: String = {
        let password = "LLKB1974"
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding(.top, 30)
                .padding(.bottom, 20)
            
            VStack(spacing: 15) {
                Text("Enter the Secret Passphrase")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                Text("Please enter the secret passphrase to verify your membership")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                SecureField("Secret Passphrase", text: $secretPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                
                NavigationLink(destination: PasswordSetupView(userData: userData), isActive: $navigateToPassword) {
                    Button(action: {
                        Task {
                            await verifyPassword()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(Color.black)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    .disabled(isLoading)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func verifyPassword() async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Hash the entered password and compare with stored hash
        let enteredPasswordData = Data(secretPassword.utf8)
        let enteredPasswordHash = SHA256.hash(data: enteredPasswordData)
        let enteredPasswordHashString = enteredPasswordHash.compactMap { String(format: "%02x", $0) }.joined()
        
        if enteredPasswordHashString == hashedPassword {
            await MainActor.run {
                navigateToPassword = true
            }
        } else {
            await MainActor.run {
                showError = true
                errorMessage = "Incorrect passphrase. Please try again."
            }
        }
    }
}

#Preview {
    NavigationStack {
        SecretPasswordView(userData: UserSignupData())
    }
} 