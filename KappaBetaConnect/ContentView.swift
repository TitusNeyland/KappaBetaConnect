//
//  ContentView.swift
//  KappaBetaConnect
//
//  Created by Titus Neyland on 4/6/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingSplash = true
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isShowingSplash {
                    SplashScreenView()
                } else {
                    if authManager.isAuthenticated {
                        MainTabView()
                    } else {
                        LoginView()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isShowingSplash)
            .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
            .onAppear {
                // Automatically dismiss splash screen after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    withAnimation {
                        isShowingSplash = false
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
