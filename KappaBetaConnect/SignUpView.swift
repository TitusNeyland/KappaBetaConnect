import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userData = UserSignupData()
    @State private var navigateToWelcome = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo at the top
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.top, 30)
            
            ScrollView {
                VStack(spacing: 15) {
                    TextField("Prefix (Optional)", text: $userData.prefix)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("First Name", text: $userData.firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Last Name", text: $userData.lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Suffix (Optional)", text: $userData.suffix)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Email", text: $userData.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone Number", text: $userData.phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                    
                    // Use NavigationLink for more reliable navigation
                    NavigationLink(destination: WelcomeView(userData: userData), isActive: $navigateToWelcome) {
                        Button(action: {
                            validateAndProceed()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Continue")
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                        .disabled(isLoading)
                    }
                    .buttonStyle(PlainButtonStyle()) // Prevents double styling
                }
                .padding(.horizontal, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func validateAndProceed() {
        isLoading = true
        
        // Basic validation
        if userData.firstName.isEmpty {
            showError(message: "Please enter your first name")
            return
        }
        
        if userData.lastName.isEmpty {
            showError(message: "Please enter your last name")
            return
        }
        
        if userData.email.isEmpty {
            showError(message: "Please enter your email address")
            return
        }
        
        if !isValidEmail(userData.email) {
            showError(message: "Please enter a valid email address")
            return
        }
        
        if userData.phoneNumber.isEmpty {
            showError(message: "Please enter your phone number")
            return
        }
        
        // Proceed to welcome screen
        isLoading = false
        navigateToWelcome = true
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
        SignUpView()
    }
} 