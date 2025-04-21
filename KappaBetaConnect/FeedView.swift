import SwiftUI

struct FeedView: View {
    @StateObject private var postRepository = PostRepository()
    @EnvironmentObject private var authManager: AuthManager
    @State private var showNewPostSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showToast = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // KB Logo
                        Image("kblogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .padding(.top, 10)
                        
                        ForEach(postRepository.posts) { post in
                            PostCard(post: post, postRepository: postRepository)
                        }
                    }
                    .padding()
                }
                .refreshable {
                    do {
                        try await postRepository.fetchPosts()
                    } catch {
                        showError = true
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .overlay(
                Button(action: {
                    showNewPostSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(red: 0.831, green: 0.686, blue: 0.216))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20),
                alignment: .bottomTrailing
            )
            
            // Centered Toast
            if showToast {
                Toast(message: "Post uploaded successfully", isShowing: $showToast)
            }
        }
        .sheet(isPresented: $showNewPostSheet) {
            CreatePostSheet(
                postRepository: postRepository,
                showError: $showError,
                errorMessage: $errorMessage,
                didCreatePost: { success in
                    if success {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            showToast = true
                        }
                    }
                }
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
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
} 
