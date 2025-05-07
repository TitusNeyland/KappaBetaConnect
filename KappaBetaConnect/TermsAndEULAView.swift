import SwiftUI

struct TermsAndEULAView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasAgreedToTerms: Bool
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service and EULA")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                Group {
                    Text("1. Content Guidelines")
                        .font(.headline)
                    Text("By using this app, you agree to:")
                        .font(.subheadline)
                    Text("• Not post any objectionable content including but not limited to: hate speech, harassment, explicit content, or illegal material")
                    Text("• Not engage in any form of abusive behavior towards other users")
                    Text("• Respect the privacy and dignity of all members")
                }
                
                Group {
                    Text("2. Content Moderation")
                        .font(.headline)
                    Text("• All content is subject to review and moderation")
                    Text("• Objectionable content will be removed within 24 hours")
                    Text("• Users who violate these terms will be removed from the platform")
                }
                
                Group {
                    Text("3. User Responsibilities")
                        .font(.headline)
                    Text("• Report any objectionable content or abusive behavior")
                    Text("• Use the blocking feature for any users who make you uncomfortable")
                    Text("• Maintain a respectful and professional environment")
                }
                
                Spacer()
                
                Button(action: {
                    hasAgreedToTerms = true
                    dismiss()
                }) {
                    Text("I Agree to the Terms")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
            .padding()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
} 