import SwiftUI

struct WelcomeView: View {
    @State private var navigateToProfile = false
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Let's get your profile set up...")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            // Automatically navigate to ProfileSetupView after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                navigateToProfile = true
            }
        }
        .navigationDestination(isPresented: $navigateToProfile) {
            ProfileSetupView()
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
} 