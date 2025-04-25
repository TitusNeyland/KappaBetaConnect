import SwiftUI
import CryptoKit

struct CharacterBoxView: View {
    let char: String
    let isFocused: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                .frame(width: 40, height: 40) // Slightly smaller boxes
            
            if !char.isEmpty {
                Circle()
                    .fill(Color.black)
                    .frame(width: 12, height: 12)
            }
        }
    }
}

struct SecretPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userData: UserSignupData
    @State private var secretPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isPassphraseVerified = false
    @FocusState private var isInputFocused: Bool
    
    private let maxLength = 8 // Length of "LLKB1974"
    
    // Store the hashed password instead of the plain text
    private let hashedPassword: String = {
        let password = "LLKB1974"
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Image("kblogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .padding(.top, geometry.size.height * 0.1)
                        .padding(.bottom, 40)
                    
                    Text("Enter the Secret Passphrase")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                    
                    Text("Please enter the secret passphrase to verify your membership")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
                    
                    // Character boxes in a scrollable container if needed
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(0..<maxLength, id: \.self) { index in
                                CharacterBoxView(
                                    char: index < secretPassword.count ? "•" : "",
                                    isFocused: isInputFocused && index == secretPassword.count
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                    .onTapGesture {
                        isInputFocused = true
                    }
                    
                    // Hidden text field for keyboard input
                    TextField("", text: $secretPassword)
                        .keyboardType(.asciiCapable)
                        .focused($isInputFocused)
                        .opacity(0)
                        .frame(width: 0, height: 0)
                        .onChange(of: secretPassword) { newValue in
                            if newValue.count > maxLength {
                                secretPassword = String(newValue.prefix(maxLength))
                            }
                        }
                        .submitLabel(.continue)
                        .onSubmit {
                            if secretPassword.count == maxLength {
                                Task {
                                    await verifyPassword()
                                }
                            } else {
                                isInputFocused = true
                            }
                        }
                    
                    Spacer()
                    
                    // Navigation link that's only active when verified
                    NavigationLink(destination: PasswordSetupView(userData: userData), isActive: $isPassphraseVerified) {
                        EmptyView()
                    }
                    
                    // Separate button for initiating verification
                    Button(action: {
                        Task {
                            await verifyPassword()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                                .foregroundColor(.white)
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(secretPassword.count == maxLength ? Color.black : Color.gray)
                    .cornerRadius(30)
                    .padding(.horizontal, 20)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                    .disabled(isLoading || secretPassword.count < maxLength)
                }
                .frame(minHeight: geometry.size.height)
            }
            .scrollDisabled(true)
            .onTapGesture {
                isInputFocused = true
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                        Text("Back")
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .toolbarColorScheme(.light, for: .navigationBar)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                // Re-enable input focus when alert is dismissed
                isInputFocused = true
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func verifyPassword() async {
        isLoading = true
        isInputFocused = false
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Hash the entered password and compare with stored hash
        let enteredPasswordData = Data(secretPassword.utf8)
        let enteredPasswordHash = SHA256.hash(data: enteredPasswordData)
        let enteredPasswordHashString = enteredPasswordHash.compactMap { String(format: "%02x", $0) }.joined()
        
        await MainActor.run {
            isLoading = false
            
            if enteredPasswordHashString == hashedPassword {
                isPassphraseVerified = true
            } else {
                showError = true
                errorMessage = "Incorrect passphrase. Please try again."
                secretPassword = ""
                isPassphraseVerified = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        SecretPasswordView(userData: UserSignupData())
    }
} 