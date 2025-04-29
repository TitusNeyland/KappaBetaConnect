import Foundation
import FirebaseMessaging
import Combine
import UIKit

class FCMService: ObservableObject {
    static let shared = FCMService()
    
    @Published var fcmToken: String?
    @Published var isFCMEnabled: Bool = false
    private var cancellables = Set<AnyCancellable>()
    private var isNewToken = false
    
    private init() {
        // Initialize with FCM disabled
        Messaging.messaging().isAutoInitEnabled = false
        setupTokenListener()
        setupNotificationObservers()
    }
    
    func enableFCM() {
        Messaging.messaging().isAutoInitEnabled = true
        isFCMEnabled = true
        setupTokenListener()
        fetchToken()
    }
    
    func disableFCM() {
        Messaging.messaging().isAutoInitEnabled = false
        isFCMEnabled = false
        deleteToken()
    }
    
    private func setupTokenListener() {
        // Listen for token updates via NotificationCenter
        NotificationCenter.default.publisher(for: Notification.Name("FCMToken"))
            .sink { [weak self] notification in
                if let token = notification.userInfo?["token"] as? String {
                    self?.handleTokenUpdate(token)
                }
            }
            .store(in: &cancellables)
        
        // Listen for token refresh notifications
        NotificationCenter.default.publisher(for: Notification.Name.MessagingRegistrationTokenRefreshed)
            .sink { [weak self] _ in
                self?.fetchToken()
            }
            .store(in: &cancellables)
        
        // Get current token if available
        fetchToken()
    }
    
    private func setupNotificationObservers() {
        // Add observer for token refresh notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(tokenRefreshNotification),
            name: Notification.Name.MessagingRegistrationTokenRefreshed,
            object: nil
        )
    }
    
    @objc private func tokenRefreshNotification() {
        print("Token refresh notification received")
        fetchToken()
    }
    
    func fetchToken() {
        guard isFCMEnabled else {
            print("FCM is disabled. Enable it first using enableFCM()")
            return
        }
        
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                // Check if this is a new token
                let storedToken = UserDefaults.standard.string(forKey: "fcmToken")
                self?.isNewToken = storedToken != token
                
                self?.fcmToken = token
                self?.handleTokenUpdate(token)
            }
        }
    }
    
    private func handleTokenUpdate(_ token: String) {
        print("FCM registration token updated: \(token)")
        
        // Store in UserDefaults
        UserDefaults.standard.set(token, forKey: "fcmToken")
        
        // If this is a new token, send it to the server and handle subscriptions
        if isNewToken {
            sendTokenToServer(token)
            handleSubscriptions(for: token)
        }
    }
    
    private func sendTokenToServer(_ token: String) {
        // TODO: Implement your server communication here
        // This is where you would send the token to your backend
        print("Sending new token to server: \(token)")
    }
    
    private func handleSubscriptions(for token: String) {
        // Subscribe to default topics
        subscribeToDefaultTopics()
        
        // You can add user-specific topic subscriptions here
        // For example:
        // subscribeToTopic("user_\(userId)")
    }
    
    // MARK: - Topic Management
    
    func subscribeToTopic(_ topic: String) {
        guard isFCMEnabled else {
            print("FCM is disabled. Enable it first using enableFCM()")
            return
        }
        
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                print("Error subscribing to topic \(topic): \(error)")
            } else {
                print("Successfully subscribed to topic: \(topic)")
            }
        }
    }
    
    func unsubscribeFromTopic(_ topic: String) {
        guard isFCMEnabled else {
            print("FCM is disabled. Enable it first using enableFCM()")
            return
        }
        
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            if let error = error {
                print("Error unsubscribing from topic \(topic): \(error)")
            } else {
                print("Successfully unsubscribed from topic: \(topic)")
            }
        }
    }
    
    private func subscribeToDefaultTopics() {
        // Subscribe to any default topics your app needs
        // For example:
        // subscribeToTopic("announcements")
        // subscribeToTopic("updates")
    }
    
    // MARK: - Notification Permissions
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
                return
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func getCurrentToken() -> String? {
        return fcmToken
    }
    
    // MARK: - Token Management
    
    func deleteToken() {
        Messaging.messaging().deleteToken { error in
            if let error = error {
                print("Error deleting FCM token: \(error)")
            } else {
                print("Successfully deleted FCM token")
                self.fcmToken = nil
                UserDefaults.standard.removeObject(forKey: "fcmToken")
            }
        }
    }
    
    deinit {
        // Remove observers when the service is deallocated
        NotificationCenter.default.removeObserver(self)
    }
} 
