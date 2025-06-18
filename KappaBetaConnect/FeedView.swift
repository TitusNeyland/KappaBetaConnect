import SwiftUI

struct FeedView: View {
    @EnvironmentObject var postRepository: PostRepository
    @StateObject private var contentModeration = ContentModerationService()
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showNewPostSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showToast = false
    
    var body: some View {
        ZStack {
            // Set background color based on color scheme
            (colorScheme == .dark ? Color(red: 0.10, green: 0.10, blue: 0.12) : Color(.systemBackground))
                .ignoresSafeArea()
            
            if postRepository.initialLoading {
                ProgressView("Loading posts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // KB Logo
                            Image("kblogo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 60)
                                .padding(.top, 10)
                            
                            if postRepository.posts.isEmpty {
                                Text("No posts yet")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(postRepository.posts) { post in
                                    PostCard(post: post, postRepository: postRepository)
                                        .onAppear {
                                            // Load more posts when reaching the last post
                                            if post.id == postRepository.posts.last?.id && !postRepository.isLoadingMore && postRepository.hasMorePosts {
                                                Task {
                                                    do {
                                                        try await postRepository.loadMorePosts()
                                                    } catch {
                                                        print("Error loading more posts: \(error.localizedDescription)")
                                                    }
                                                }
                                            }
                                        }
                                }
                                
                                // Loading indicator
                                if postRepository.isLoadingMore {
                                    ProgressView()
                                        .padding()
                                }
                                
                                // No more posts indicator
                                if !postRepository.hasMorePosts && !postRepository.posts.isEmpty {
                                    Text("No more posts")
                                        .foregroundColor(.gray)
                                        .padding()
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await refreshData()
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
            }
            
            // Centered Toast
            if showToast {
                Toast(message: "Post uploaded successfully", isShowing: $showToast)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(destination: EmptyView()) {
                    EmptyView()
                }
                .opacity(0)
            }
        }
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
                Text("Back")
                    .foregroundColor(.primary)
            }
        })
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
            // Initial load of posts
            await refreshData()
        }
    }
    
    private func refreshData() async {
        do {
            if let currentUserId = authManager.currentUser?.id {
                let blockedUsers = try await contentModeration.getBlockedUsers(userId: currentUserId)
                postRepository.updateBlockedUsers(blockedUsers)
            }
            try await postRepository.fetchPosts()
            // Prefetch the next batch in the background
            Task {
                try? await postRepository.loadMorePosts()
            }
        } catch {
            await MainActor.run {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
} 
