//
//  ContentView.swift
//  KappaBetaConnect
//
//  Created by Titus Neyland on 4/6/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingSplash = true
    
    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashScreenView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Automatically dismiss splash screen after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    isShowingSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
