import SwiftUI

struct ProfileSetupView: View {
    @State private var career = ""
    @State private var major = ""
    @State private var job = ""
    @State private var company = ""
    @State private var navigateToInitiation = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.top, 30)
            
            ScrollView {
                VStack(spacing: 15) {
                    TextField("Career Field", text: $career)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Major", text: $major)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Current Job Title", text: $job)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Company", text: $company)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    NavigationLink(destination: InitiationDetailsView()) {
                        Text("Continue")
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
        ProfileSetupView()
    }
} 