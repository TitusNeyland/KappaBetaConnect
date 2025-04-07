import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
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
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                ZStack(alignment: .trailing) {
                    if showPassword {
                        TextField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
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
                    // Handle login action here
                }) {
                    Text("Login")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                }
                
                Button("Forgot Password?") {
                    // Handle forgot password action
                }
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Sign up prompt
            HStack {
                Text("Not a member?")
                    .foregroundColor(.gray)
                Button("Sign Up") {
                    // Handle sign up action
                }
                .foregroundColor(.black)
                .fontWeight(.bold)
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
    }
}


#Preview {
    LoginView()
} 
