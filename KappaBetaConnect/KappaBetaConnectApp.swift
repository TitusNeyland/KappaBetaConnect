//
//  KappaBetaConnectApp.swift
//  KappaBetaConnect
//
//  Created by Titus Neyland on 4/6/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct KappaBetaConnectApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()
    @StateObject private var userRepository = UserRepository()
    @StateObject private var birthdayService = BirthdayService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(userRepository)
                .environmentObject(birthdayService)
        }
    }
}
