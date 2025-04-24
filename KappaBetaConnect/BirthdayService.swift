import SwiftUI

class BirthdayService: ObservableObject {
    static let shared = BirthdayService()
    @Published var shouldShowBirthdayDialog = false
    private var lastShownDate: Date?
    
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
} 