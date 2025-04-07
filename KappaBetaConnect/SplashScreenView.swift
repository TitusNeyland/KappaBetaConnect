import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black // Using black background as it's one of Alpha Phi Alpha's colors
                .ignoresSafeArea()
            
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .padding()
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeOut(duration: 1.2), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    SplashScreenView()
}


