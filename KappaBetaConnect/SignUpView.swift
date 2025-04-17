import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userData = UserSignupData()
    @State private var navigateToWelcome = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let states = ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", 
                 "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", 
                 "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", 
                 "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", 
                 "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]
    
    let prefixes = ["Mr.", "Mrs.", "Ms.", "Dr.", "Prof.", "Rev.", "Hon."]
    let suffixes = ["Jr.", "Sr.", "II", "III", "IV", "V", "Ph.D.", "M.D.", "Esq."]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Logo at the top
                Image("kblogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                
                // Personal Information Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Personal Information")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                    
                    VStack(spacing: 15) {
                        // Name Fields
                        HStack(spacing: 10) {
                            // Prefix Picker
                            Picker("", selection: $userData.prefix) {
                                Text("Prefix").tag("")
                                ForEach(prefixes, id: \.self) { prefix in
                                    Text(prefix).tag(prefix)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.black)
                            .frame(maxWidth: 100)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 55)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            
                            CustomTextField(text: $userData.firstName, placeholder: "First Name", keyboardType: .default, textContentType: .givenName, allowWhitespace: false, autoCapitalizeFirstLetter: true)
                                .customTextField()
                        }
                        
                        HStack(spacing: 10) {
                            CustomTextField(text: $userData.lastName, placeholder: "Last Name", keyboardType: .default, textContentType: .familyName, allowWhitespace: false, autoCapitalizeFirstLetter: true)
                                .customTextField()
                            
                            // Suffix Picker
                            Picker("", selection: $userData.suffix) {
                                Text("Suffix").tag("")
                                ForEach(suffixes, id: \.self) { suffix in
                                    Text(suffix).tag(suffix)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.black)
                            .frame(maxWidth: 100)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 55)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 30)
                }
                
                // Location Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Location")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                    
                    VStack(spacing: 15) {
                        CustomTextField(text: $userData.city, placeholder: "City", keyboardType: .default, textContentType: .addressCity, autoCapitalizeFirstLetter: true)
                            .customTextField()
                        
                        // State Picker
                        HStack {
                            Text("State")
                                .foregroundColor(.gray)
                            Spacer()
                            Picker("State", selection: $userData.state) {
                                Text("Select State").tag("")
                                ForEach(states, id: \.self) { state in
                                    Text(state).tag(state)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.black)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 30)
                }
                
                // Contact Information Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Contact Information")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                    
                    VStack(spacing: 15) {
                        CustomTextField(text: $userData.email, placeholder: "Email", keyboardType: .emailAddress, textContentType: .emailAddress)
                            .customTextField()
                        
                        CustomTextField(text: $userData.phoneNumber, placeholder: "Phone Number", keyboardType: .phonePad, textContentType: .telephoneNumber)
                            .customTextField()
                    }
                    .padding(.horizontal, 30)
                }
                
                // Continue Button
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
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(Color.black)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                    .padding(.top, 40)
                    .padding(.bottom, 30)
                    .disabled(isLoading)
                }
                .buttonStyle(PlainButtonStyle())
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
        
        if userData.city.isEmpty {
            showError(message: "Please enter your city")
            return
        }
        
        if userData.state.isEmpty {
            showError(message: "Please select your state")
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
