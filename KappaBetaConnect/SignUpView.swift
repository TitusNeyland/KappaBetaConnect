import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var prefix = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var suffix = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    
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
                    TextField("Prefix (Optional)", text: $prefix)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Suffix (Optional)", text: $suffix)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                    
                    Button(action: {
                        // Handle sign up action
                    }) {
                        Text("Sign Up")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
} 