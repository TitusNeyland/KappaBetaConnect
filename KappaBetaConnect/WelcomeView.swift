import SwiftUI

struct WelcomeView: View {
    @State private var navigateToProfile = false
    var userData: UserSignupData
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Let's get your profile set up...")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Hidden NavigationLink
            NavigationLink(destination: ProfileSetupView(userData: userData), isActive: $navigateToProfile) {
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            // Automatically navigate to ProfileSetupView after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                navigateToProfile = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView(userData: UserSignupData())
    }
} 