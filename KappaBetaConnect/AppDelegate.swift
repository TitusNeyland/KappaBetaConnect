import UIKit
import Firebase
import FirebaseMessaging
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Set the messaging delegate
        Messaging.messaging().delegate = self
        
        // Register for remote notifications
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        
        // Only register for remote notifications if already authorized
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 Did register for remote notifications with token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("📱 Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication,
                    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📱 Did receive remote notification: \(userInfo)")
        completionHandler(.newData)
    }
    
    // MARK: - MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        
        // Subscribe to the 'allUsers' topic
        Messaging.messaging().subscribe(toTopic: "allUsers") { error in
            if let error = error {
                print("Error subscribing to topic: \(error.localizedDescription)")
            } else {
                print("Subscribed to 'allUsers' topic")
            }
        }
        
        // Save FCM token to Firestore user document
        if let userId = Auth.auth().currentUser?.uid, let token = fcmToken {
            let db = Firestore.firestore()
            db.collection("users").document(userId).setData(["fcmToken": token], merge: true)
        }
    }
} 