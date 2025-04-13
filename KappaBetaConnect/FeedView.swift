import SwiftUI

struct FeedView: View {
    @StateObject private var postRepository = PostRepository()
    @EnvironmentObject private var authManager: AuthManager
    @State private var showNewPostSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
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
            .sheet(isPresented: $showNewPostSheet) {
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