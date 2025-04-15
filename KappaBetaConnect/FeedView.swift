import SwiftUI

struct FeedView: View {
    @StateObject private var postRepository = PostRepository()
    @EnvironmentObject private var authManager: AuthManager
    @State private var showNewPostSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showToast = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(postRepository.posts) { post in
                                PostCard(post: post, postRepository: postRepository)
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Feed")
                .overlay(
                    Button(action: {
                        showNewPostSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.black)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20),
                    alignment: .bottomTrailing
                )
                
                // Toast
                if showToast {
                    Toast(message: "Post uploaded successfully", isShowing: $showToast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showNewPostSheet, onDismiss: {
                // Show toast when returning from successful post creation
                if !showError {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        showToast = true
                    }
                }
            }) {
                CreatePostSheet(
                    postRepository: postRepository,
                    showError: $showError,
                    errorMessage: $errorMessage
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                do {
                    try await postRepository.fetchPosts()
                } catch {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
} 