import SwiftUI
import PhotosUI

struct ProfilePicturePromptView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var navigateToMain = false
    @State private var showError = false
    @State private var errorMessage = ""
    @StateObject private var userRepository = UserRepository()
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image("kblogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            
            Text("Let's Put a Face to Your Name")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text("Add a profile picture to help your brothers recognize you")
                .font(.system(size: 17))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Profile Picture Picker
            PhotosPicker(selection: $selectedItem, matching: .images) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 2))
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 150, height: 150)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }
            }
            .padding(.vertical, 20)
            
            Spacer()
            
            // Navigation Buttons
            VStack(spacing: 15) {
                Button(action: {
                    if let image = selectedImage {
                        Task {
                            await uploadProfileImage(image)
                        }
                    } else {
                        navigateToMain = true
                    }
                }) {
                    if isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(selectedImage != nil ? "Continue" : "Skip for Now")
                            .foregroundColor(.white)
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(Color.black)
                .cornerRadius(30)
                .padding(.horizontal, 20)
                .disabled(isUploading)
            }
            .padding(.bottom, 30)
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        
        NavigationLink(destination: MainTabView().navigationBarBackButtonHidden(true), isActive: $navigateToMain) {
            EmptyView()
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) async {
        guard let userId = authManager.userId else {
            showError = true
            errorMessage = "User ID not found"
            return
        }
        
        isUploading = true
        do {
            let imageURL = try await ImageService.shared.uploadProfileImage(image, userId: userId)
            if var user = userRepository.currentUser {
                user.profileImageURL = imageURL.absoluteString
                try await userRepository.updateUser(user)
            }
            navigateToMain = true
        } catch {
            showError = true
            errorMessage = "Failed to upload profile picture: \(error.localizedDescription)"
        }
        isUploading = false
    }
}

#Preview {
    NavigationStack {
        ProfilePicturePromptView()
            .environmentObject(AuthManager())
    }
} 