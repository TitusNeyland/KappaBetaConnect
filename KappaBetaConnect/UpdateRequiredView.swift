import SwiftUI

struct UpdateRequiredView: View {
    @EnvironmentObject var versionManager: VersionManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Update Required")
                .font(.title)
                .fontWeight(.bold)
            
            Text("A new version of Kappa Beta Connect is available. Please update to continue using the app.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Minimum version required: \(versionManager.minimumVersion)")
                .font(.subheadline)
                .foregroundColor(.white)
            
            Button(action: {
                versionManager.openAppStore()
            }) {
                Text("Update Now")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
        .preferredColorScheme(.dark)
    }
} 