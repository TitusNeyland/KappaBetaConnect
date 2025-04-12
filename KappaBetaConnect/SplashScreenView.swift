import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var pulsate = false
    
    var body: some View {
        ZStack {
            Color.black // Using black background as it's one of Alpha Phi Alpha's colors
                .ignoresSafeArea()
            
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .scaleEffect(isAnimating ? 1.0 : 0.1)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(pulsate ? 1.05 : 1.0) // Subtle pulsing effect
                .animation(
                    .spring(
                        response: 0.8,
                        dampingFraction: 0.7,
                        blendDuration: 0.5
                    ),
                    value: isAnimating
                )
        }
        .onAppear {
            // Sequence of animations
            withAnimation(nil) {
                // Start with zero scale and opacity
                isAnimating = false
                pulsate = false
            }
            
            // Delay slightly for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // First grow the logo
                withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                    isAnimating = true
                }
                
                // Then add subtle pulsing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        pulsate = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}


