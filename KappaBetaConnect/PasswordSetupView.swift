import SwiftUI

struct PasswordSetupView: View {
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var navigateToMain = false
    
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
                    
                    // Confirm Password Field
                    ZStack(alignment: .trailing) {
                        if showConfirmPassword {
                            TextField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Button(action: {
                            showConfirmPassword.toggle()
                        }) {
                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                    
                    Button(action: {
                        // Here you would typically validate passwords and handle account creation
                        navigateToMain = true
                    }) {
                        Text("Complete Setup")
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
        .navigationDestination(isPresented: $navigateToMain) {
            MainTabView()
                .navigationBarBackButtonHidden(true)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        PasswordSetupView()
    }
} 