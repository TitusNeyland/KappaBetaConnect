import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var userData: UserSignupData
    @State private var navigateToInitiation = false
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.top, 30)
            
            ScrollView {
                VStack(spacing: 15) {
                    TextField("Career Field", text: $userData.careerField)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Major", text: $userData.major)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Current Job Title", text: $userData.jobTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Company", text: $userData.company)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    NavigationLink(destination: InitiationDetailsView(userData: userData), isActive: $navigateToInitiation) {
                        Button(action: {
                            navigateToInitiation = true
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
                    .buttonStyle(PlainButtonStyle())
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
        ProfileSetupView(userData: UserSignupData())
    }
} 