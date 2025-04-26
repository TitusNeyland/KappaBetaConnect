import SwiftUI
import FirebaseFirestore

class BirthdayService: ObservableObject {
    static let shared = BirthdayService()
    @Published var shouldShowBirthdayDialog = false
    @Published var notificationsEnabled = false
    private var lastShownDate: Date?
    private let notificationService = NotificationService.shared
    private let db = Firestore.firestore()
    
    private init() {}
    
    func checkAndShowBirthdayDialog() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Only show the dialog once per day
        if let lastShown = lastShownDate,
           Calendar.current.isDate(lastShown, inSameDayAs: today) {
            return
        }
        
        shouldShowBirthdayDialog = true
        lastShownDate = today
    }
    
    func scheduleBirthdayNotifications(for users: [User]) {
        guard notificationsEnabled else { return }
        for user in users {
            notificationService.scheduleBirthdayNotification(for: user)
        }
    }
    
    @MainActor
    func setupBirthdayNotifications() async {
        do {
            // Check current authorization status first
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            
            switch settings.authorizationStatus {
            case .notDetermined:
                // Request permission if not determined
                do {
                    try await notificationService.requestPermission()
                    notificationsEnabled = true
                } catch {
                    print("Failed to get notification permission: \(error.localizedDescription)")
                    notificationsEnabled = false
                    return
                }
            case .authorized:
                notificationsEnabled = true
            default:
                notificationsEnabled = false
                return
            }
            
            // Only proceed if notifications are enabled
            guard notificationsEnabled else { return }
            
            // Fetch all users and schedule their birthday notifications
            let snapshot = try await db.collection("users").getDocuments()
            let users = snapshot.documents.compactMap { document -> User? in
                try? document.data(as: User.self)
            }
            
            scheduleBirthdayNotifications(for: users)
        } catch {
            print("Error setting up birthday notifications: \(error.localizedDescription)")
        }
    }
} 