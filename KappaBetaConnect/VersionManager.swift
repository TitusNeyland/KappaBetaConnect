import SwiftUI
import FirebaseRemoteConfig

class VersionManager: ObservableObject {
    static let shared = VersionManager()
    private let remoteConfig = RemoteConfig.remoteConfig()
    
    @Published var isUpdateRequired = false
    @Published var minimumVersion: String = ""
    
    private init() {
        setupRemoteConfig()
    }
    
    private func setupRemoteConfig() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // For development, set to 0. For production, use a higher value
        remoteConfig.configSettings = settings
        
        // Set default values
        remoteConfig.setDefaults([
            "minimum_required_version": "1.0.0" as NSObject
        ])
    }
    
    func checkForUpdates() async {
        do {
            try await remoteConfig.fetchAndActivate()
            
            // Get the minimum required version from Remote Config
            let minimumRequiredVersion = remoteConfig.configValue(forKey: "minimum_required_version").stringValue ?? "1.0.0"
            
            // Get current app version
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            
            // Compare versions
            if compareVersions(currentVersion, minimumRequiredVersion) == .orderedAscending {
                await MainActor.run {
                    self.minimumVersion = minimumRequiredVersion
                    self.isUpdateRequired = true
                }
            }
        } catch {
            print("Error fetching remote config: \(error)")
        }
    }
    
    private func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        return version1.compare(version2, options: .numeric)
    }
    
    func openAppStore() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id6745492490") {
            UIApplication.shared.open(url)
        }
    }
} 