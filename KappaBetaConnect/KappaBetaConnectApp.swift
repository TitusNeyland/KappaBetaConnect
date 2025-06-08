//
//  KappaBetaConnectApp.swift
//  KappaBetaConnect
//
//  Created by Titus Neyland on 4/6/25.
//

import SwiftUI
import FirebaseCore

@main
struct KappaBetaConnectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()
    @StateObject private var userRepository = UserRepository()
    @StateObject private var birthdayService = BirthdayService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var versionManager = VersionManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if versionManager.isUpdateRequired {
                    UpdateRequiredView()
                        .environmentObject(versionManager)
                } else {
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(userRepository)
                        .environmentObject(birthdayService)
                        .environmentObject(notificationService)
                        .environmentObject(versionManager)
                        .environmentObject(themeManager)
                        .preferredColorScheme(themeManager.colorScheme)
                        .task {
                            await birthdayService.setupBirthdayNotifications()
                            do {
                                try await notificationService.requestPermission()
                            } catch {
                                print("Failed to request notification permission: \(error.localizedDescription)")
                            }
                            // Check for app updates
                            await versionManager.checkForUpdates()
                        }
                }
            }
        }
    }
}
