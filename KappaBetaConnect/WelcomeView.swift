import SwiftUI

struct WelcomeView: View {
    @State private var navigateToProfile = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.top, 50)
            
            Text("Let's get your profile set up...")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 30)
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