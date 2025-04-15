import SwiftUI

struct BioEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userRepository: UserRepository
    @State private var newBio: String
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(userRepository: UserRepository, currentBio: String?) {
        self.userRepository = userRepository
        _newBio = State(initialValue: currentBio ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Your Bio")
                    .font(.headline)
                    .padding(.top)
                
                TextEditor(text: $newBio)
                    .frame(height: 200)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4))
                    )
                    .padding(.horizontal)
                
                Text("Tell us about yourself, your career, and your interests")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .navigationTitle("Edit Bio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            do {
                                if var user = userRepository.currentUser {
                                    user.bio = newBio.trimmingCharacters(in: .whitespacesAndNewlines)
                                    try await userRepository.updateUser(user)
                                    dismiss()
                                }
                            } catch {
                                showError = true
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
} 