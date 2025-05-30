import UserNotifications
import FirebaseMessaging
import UIKit
import SwiftUI

class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    @Published var selectedUserId: String?
    @Published var selectedEventId: String?
    @Published var selectedPostId: String?
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission() async throws {
        print("Checking notification settings...")
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        print("Current authorization status: \(settings.authorizationStatus.rawValue)")
        
        switch settings.authorizationStatus {
        case .notDetermined:
            print("Requesting notification permission...")
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            print("Permission request result: \(granted)")
            
            if granted {
                print("Permission granted, registering for remote notifications...")
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("Successfully registered for remote notifications")
            } else {
                print("Permission denied by user")
                throw NSError(domain: "NotificationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Notification permission denied by user"])
            }
        case .authorized:
            print("Notifications already authorized, registering for remote notifications...")
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            print("Successfully registered for remote notifications")
        case .denied:
            print("Notifications previously denied")
            throw NSError(domain: "NotificationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Notification permission previously denied"])
        case .provisional:
            print("Provisional authorization granted")
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        case .ephemeral:
            print("Ephemeral authorization granted")
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        @unknown default:
            print("Unknown authorization status")
            throw NSError(domain: "NotificationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown notification authorization status"])
        }
    }
    
    func scheduleBirthdayNotification(for user: User) {
        let content = UNMutableNotificationContent()
        content.title = "Birthday Celebration! 🎉"
        content.body = "Today is \(user.firstName) \(user.lastName)'s birthday! Don't forget to wish them a happy birthday!"
        content.sound = .default
        content.userInfo = ["userId": user.id ?? ""]  // Add user ID to notification payload
        
        // Get the user's next birthday
        let calendar = Calendar.current
        let now = Date()
        let birthday = user.birthday
        
        // Create date components for the next birthday
        var birthdayComponents = calendar.dateComponents([.month, .day], from: birthday)
        birthdayComponents.hour = 8 // Send notification at 8:53 AM
        birthdayComponents.minute = 53
        
        // Create the trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: birthdayComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: "birthday-\(user.id ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling birthday notification: \(error.localizedDescription)")
            }
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📱 Will present notification: \(notification.request.content.title)")
        print("📱 Notification payload: \(notification.request.content.userInfo)")
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📱 Did receive notification response: \(response.notification.request.content.title)")
        print("📱 Notification payload: \(response.notification.request.content.userInfo)")
        let userInfo = response.notification.request.content.userInfo
        
        // Handle different notification types
        if let type = userInfo["type"] as? String {
            switch type {
            case "newEvent":
                if let eventId = userInfo["eventId"] as? String {
                    DispatchQueue.main.async {
                        self.selectedEventId = eventId
                    }
                }
            case "newMember":
                if let userId = userInfo["userId"] as? String {
                    DispatchQueue.main.async {
                        self.selectedUserId = userId
                    }
                }
            case "newPost", "newLike", "newComment", "mention":
                if let postId = userInfo["postId"] as? String {
                    DispatchQueue.main.async {
                        self.selectedPostId = postId
                    }
                }
            default:
                break
            }
        } else if let userId = userInfo["userId"] as? String {
            // Handle legacy notifications (birthday notifications)
            DispatchQueue.main.async {
                self.selectedUserId = userId
            }
        }
        
        completionHandler()
    }
} 
