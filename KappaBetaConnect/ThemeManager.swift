import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var colorScheme: ColorScheme? {
        isDarkMode ? .dark : .light
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
    
    func setTheme(_ isDark: Bool) {
        isDarkMode = isDark
    }
} 