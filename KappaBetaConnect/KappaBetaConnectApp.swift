//
//  KappaBetaConnectApp.swift
//  KappaBetaConnect
//
//  Created by Titus Neyland on 4/6/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Set up notification center
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // Initialize FCM service
        _ = FCMService.shared
        
        return true
    }
    
    // Handle FCM token refresh
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
    
    // Handle notification presentation when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // Handle FCM message
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Show notification even when app is in foreground
        completionHandler([[.banner, .sound]])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle FCM message
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        completionHandler()
    }
    
    // Handle APNs token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

@main
struct KappaBetaConnectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()
    @StateObject private var userRepository = UserRepository()
    @StateObject private var birthdayService = BirthdayService.shared
    @StateObject private var fcmService = FCMService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(userRepository)
                .environmentObject(birthdayService)
                .environmentObject(fcmService)
                .task {
                    await birthdayService.setupBirthdayNotifications()
                    // Request notification permissions and enable FCM
                    await requestNotificationPermissions()
                }
        }
    }
    
    private func requestNotificationPermissions() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            if granted {
                // Enable FCM only if user granted permission
                fcmService.enableFCM()
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } catch {
            print("Error requesting notification permissions: \(error)")
        }
    }
}
