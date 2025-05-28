import SwiftUI
import UIKit
import PhotosUI

// Toast View
struct Toast: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut) {
                    isShowing = false
                }
            }
        }
    }
}

// User Info Section
struct PostUserInfoView: View {
    let post: Post
    let profileImageURL: String?
    let isCurrentUser: Bool
    let onDelete: () -> Void
    let onEdit: (() -> Void)?
    let postRepository: PostRepository
    @State private var showReportSheet = false
    @State private var showBlockAlert = false
    @State private var showError = false
    @State private var errorMessage = ""
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var contentModeration = ContentModerationService()
    
    var body: some View {
        HStack {
            NavigationLink(destination: ProfileView(userId: post.authorId)) {
                if let profileURL = profileImageURL,
                   let url = URL(string: profileURL) {
                    AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                        }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                }
            }
            
            VStack(alignment: .leading) {
                    Text(post.authorName)
                        .font(.headline)
                Text(post.timestamp.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if !isCurrentUser {
                Menu {
                    Button(role: .destructive) {
                        showReportSheet = true
                    } label: {
                        Label("Report", systemImage: "exclamationmark.triangle")
                    }
                    
                    Button(role: .destructive) {
                        showBlockAlert = true
                    } label: {
                        Label("Block User", systemImage: "person.fill.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .font(.system(size: 22, weight: .bold))
                        .padding(12)
                        .background(Color(.systemGray6).opacity(0.7))
                        .clipShape(Circle())
                        .contentShape(Rectangle())
                }
            } else {
                HStack(spacing: 12) {
                    Button(action: { onEdit?() }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.black)
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportContentView(post: post)
        }
        .alert("Block User", isPresented: $showBlockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) {
                blockUser()
            }
        } message: {
            Text("Are you sure you want to block this user? You won't see their content anymore.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func blockUser() {
        guard let currentUserId = authManager.currentUser?.id else { return }
        
        Task {
            do {
                // Block the user
                try await contentModeration.blockUser(userId: currentUserId, blockedUserId: post.authorId)
                
                // Get updated blocked users list
                let blockedUsers = try await contentModeration.getBlockedUsers(userId: currentUserId)
                
                // Update UI on main thread
                await MainActor.run {
                    // Update post repository with new blocked users list
                    postRepository.updateBlockedUsers(blockedUsers)
                }
                
                // Refresh the feed
                try await postRepository.fetchPosts()
                
                // Dismiss the alert on main thread
                await MainActor.run {
                    showBlockAlert = false
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct ReportContentView: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var contentModeration = ContentModerationService()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Report Content")) {
                    TextEditor(text: $reason)
                        .frame(height: 100)
                }
                
                Section {
                    Button("Submit Report") {
                        submitReport()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Report Content")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func submitReport() {
        guard let currentUserId = authManager.currentUser?.id else { return }
        
        Task {
            do {
                try await contentModeration.reportContent(
                    contentId: post.id ?? "",
                    reportedBy: currentUserId,
                    reason: reason
                )
                dismiss()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}

// Interaction Buttons Section
struct PostInteractionButtonsView: View {
    let post: Post
    let isLiked: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onLike) {
                HStack {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                    Text("Like")
                }
                .foregroundColor(isLiked ? .red : .gray)
            }
            
            Button(action: onComment) {
                HStack {
                    Image(systemName: "bubble.right")
                    Text("Comment")
                }
                .foregroundColor(.gray)
            }
            
            Button(action: onShare) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .foregroundColor(.gray)
            }
        }
    }
}

// Comments Section
struct PostCommentsView: View {
    let post: Post
    let onViewAllComments: () -> Void
    
    private var recentComments: [Comment] {
        Array(post.comments.suffix(2).reversed())
    }
    
    var body: some View {
        if !post.comments.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(recentComments) { comment in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(comment.authorName)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                            Text(comment.timestamp.timeAgoDisplay())
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        Text(comment.content)
                            .font(.caption)
                    }
                }
                
                if post.comments.count > 2 {
                    Button(action: onViewAllComments) {
                        Text("View all \(post.comments.count) comments")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}

// Comments Sheet View
struct CommentsSheetView: View {
    let post: Post
    @Binding var showSheet: Bool
    @Binding var newComment: String
    let onComment: () -> Void
    let postRepository: PostRepository
    var onCommentAdded: ((Comment) -> Void)? = nil
    var onCommentDeleted: ((String) -> Void)? = nil // commentId
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var userRepository = UserRepository()
    @State private var showDeleteAlert = false
    @State private var commentToDelete: Comment?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showUserSearch = false
    @State private var searchQuery = ""
    @State private var searchResults: [User] = []
    @State private var selectedUser: User?
    @State private var mentionStartIndex: Int?
    @State private var authorProfileImageURL: String?
    @State private var currentPost: Post
    @State private var showProfanityAlert = false
    @State private var lastCheckedComment = ""
    @State private var animatePop = false
    @State private var showEditSheet = false
    
    init(post: Post, showSheet: Binding<Bool>, newComment: Binding<String>, onComment: @escaping () -> Void, postRepository: PostRepository, onCommentAdded: ((Comment) -> Void)? = nil, onCommentDeleted: ((String) -> Void)? = nil) {
        self.post = post
        self._showSheet = showSheet
        self._newComment = newComment
        self.onComment = onComment
        self.postRepository = postRepository
        self.onCommentAdded = onCommentAdded
        self.onCommentDeleted = onCommentDeleted
        _currentPost = State(initialValue: post)
    }
    
    private func isCurrentUserComment(_ comment: Comment) -> Bool {
        comment.authorId == authManager.currentUser?.id
    }
    
    private func handleTextChange(_ text: String) {
        newComment = text
        
        // Check for @ symbol
        if let lastAtSymbolIndex = text.lastIndex(of: "@") {
            let searchText = String(text[text.index(after: lastAtSymbolIndex)...])
            if !searchText.isEmpty {
                mentionStartIndex = text.distance(from: text.startIndex, to: lastAtSymbolIndex)
                searchQuery = searchText
                searchUsers()
                showUserSearch = true
            } else {
                showUserSearch = false
            }
        } else {
            showUserSearch = false
        }
    }
    
    private func searchUsers() {
        Task {
            do {
                let users = try await userRepository.searchUsers(byName: searchQuery)
                await MainActor.run {
                    searchResults = users.filter { $0.id != authManager.currentUser?.id }
                }
            } catch {
                print("Error searching users: \(error.localizedDescription)")
            }
        }
    }
    
    private func selectUser(_ user: User) {
        guard let startIndex = mentionStartIndex else { return }
        
        let mentionText = "@\(user.firstName) \(user.lastName)"
        
        // Convert integer indices to String.Index
        let startStringIndex = newComment.index(newComment.startIndex, offsetBy: startIndex)
        let endStringIndex = newComment.index(startStringIndex, offsetBy: newComment.count - startIndex)
        let range = startStringIndex..<endStringIndex
        
        // Replace the @search with the full mention
        newComment.replaceSubrange(range, with: mentionText)
        
        // Add the mention to the comment
        let mention = Mention(
            id: UUID().uuidString,
            userId: user.id ?? "",
            userName: "\(user.firstName) \(user.lastName)",
            range: startIndex..<(startIndex + mentionText.count)
        )
        
        // Store the mention (you'll need to handle this when creating the comment)
        selectedUser = user
        showUserSearch = false
        mentionStartIndex = nil
    }
    
    private func handleComment() {
        guard let currentUser = authManager.currentUser else {
            Task { @MainActor in
                showError = true
                errorMessage = "You must be logged in to comment"
            }
            return
        }
        let commentContent = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !commentContent.isEmpty else { return }
        // Content filtering for comments
        if commentContent != lastCheckedComment {
            if ContentFilteringService.shared.containsProfanity(commentContent) {
                showProfanityAlert = true
                return
            }
            lastCheckedComment = commentContent
        }
        var mentions: [Mention] = []
        let words = commentContent.components(separatedBy: .whitespacesAndNewlines)
        var currentIndex = 0
        for word in words {
            if word.hasPrefix("@") {
                let userName = String(word.dropFirst())
                if let user = selectedUser {
                    let mention = Mention(
                        id: UUID().uuidString,
                        userId: user.id ?? "",
                        userName: userName,
                        range: currentIndex..<(currentIndex + word.count)
                    )
                    mentions.append(mention)
                }
            }
            currentIndex += word.count + 1 // +1 for the space
        }
        Task {
            do {
                let comment = try await postRepository.addComment(
                    postId: post.id ?? "",
                    content: commentContent,
                    authorId: currentUser.id ?? "",
                    authorName: "\(currentUser.firstName) \(currentUser.lastName)",
                    mentions: mentions
                )
                await MainActor.run {
                    onCommentAdded?(comment)
                    newComment = ""
                    showSheet = false
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Post content at the top
                    VStack(alignment: .leading, spacing: 12) {
                        // Author info
                        HStack {
                            if let profileImageURL = authorProfileImageURL,
                               let url = URL(string: profileImageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(currentPost.authorName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text(currentPost.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        
                        // Post content
                        Text(currentPost.content)
                            .font(.system(size: 17))
                            .fontWeight(.regular)
                            .padding(.vertical, 4)
                        
                        // Post stats
                        HStack(spacing: 20) {
                            Text("\(currentPost.likes.count) likes")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("\(currentPost.comments.count) comments")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("\(currentPost.shareCount) shares")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    
                    Divider()
                    
                    // Comments list
                    List {
                        ForEach(currentPost.comments.reversed()) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(comment.authorName)
                                        .font(.headline)
                                    Spacer()
                                    Text(comment.timestamp.timeAgoDisplay())
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(createAttributedString(from: comment))
                                    .font(.body)
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if isCurrentUserComment(comment) {
                                    Button(role: .destructive) {
                                        commentToDelete = comment
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    
                    // Comment input field with user search overlay
                    ZStack(alignment: .top) {
                        HStack(alignment: .center, spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1.2)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                                CustomTextEditor(text: $newComment, placeholder: "Add a comment...")
                                    .padding(8)
                                    .frame(minHeight: 40, maxHeight: 100, alignment: .center)
                                    .onChange(of: newComment) { handleTextChange($0) }
                            }
                            .frame(minHeight: 40, maxHeight: 100)
                            
                            Button(action: handleComment) {
                                Text("Post")
                                    .fontWeight(.medium)
                            }
                            .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .foregroundColor(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .primary)
                            .padding(.leading, 4)
                            .frame(minHeight: 40)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        
                        // User search overlay
                        if showUserSearch && !searchResults.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(searchResults) { user in
                                    Button(action: { selectUser(user) }) {
                                        HStack {
                                            if let profileImageURL = user.profileImageURL,
                                               let url = URL(string: profileImageURL) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                } placeholder: {
                                                    ProgressView()
                                                }
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                            } else {
                                                Circle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 40, height: 40)
                                                    .overlay(
                                                        Image(systemName: "person.fill")
                                                            .foregroundColor(.gray)
                                                    )
                                            }
                                            
                                            VStack(alignment: .leading) {
                                                Text("\(user.firstName) \(user.lastName)")
                                                    .font(.headline)
                                                Text(user.email ?? "")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding()
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if user.id != searchResults.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                            .frame(maxHeight: 250)
                            .offset(y: -10)
                        }
                    }
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showSheet = false
                    }
                    .foregroundColor(Color(.label))
                }
            }
            .alert("Delete Comment", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let comment = commentToDelete {
                        deleteComment(comment)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this comment? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Inappropriate Content", isPresented: $showProfanityAlert) {
                Button("OK", role: .cancel) {
                    lastCheckedComment = newComment
                }
            } message: {
                Text("Your comment contains inappropriate language. Please revise your content to maintain a respectful community environment.")
            }
            .task {
                do {
                    let user = try await userRepository.getUser(withId: currentPost.authorId)
                    authorProfileImageURL = user?.profileImageURL
                } catch {
                    print("Error fetching user profile image: \(error.localizedDescription)")
                }
            }
            .onAppear {
                postRepository.startSinglePostListener(postId: post.id ?? "") { updatedPost in
                    if let post = updatedPost {
                        currentPost = post
                    }
                }
            }
            .onDisappear {
                postRepository.stopSinglePostListener(postId: post.id ?? "")
            }
        }
    }
    
    private func createAttributedString(from comment: Comment) -> AttributedString {
        var attributed = AttributedString(comment.content)
        
        // Style mentions
        for mention in comment.mentions {
            let startIndex = comment.content.index(comment.content.startIndex, offsetBy: mention.range.lowerBound)
            let endIndex = comment.content.index(comment.content.startIndex, offsetBy: mention.range.upperBound)
            let range = startIndex..<endIndex
            
            if let attributedRange = Range(range, in: attributed) {
                attributed[attributedRange].foregroundColor = .blue
                attributed[attributedRange].link = URL(string: "user://\(mention.userId)")
            }
        }
        
        return attributed
    }
    
    private func deleteComment(_ comment: Comment) {
        Task {
            do {
                try await postRepository.deleteComment(postId: post.id ?? "", commentId: comment.id ?? "")
                await MainActor.run {
                    onCommentDeleted?(comment.id ?? "")
                }
            } catch {
                showError = true
                errorMessage = "Failed to delete comment: \(error.localizedDescription)"
            }
        }
    }
}

// Add this before the PostCard struct
class UserCacheWrapper {
    let user: User
    let timestamp: Date
    
    init(user: User) {
        self.user = user
        self.timestamp = Date()
    }
    
    var isExpired: Bool {
        // Cache expires after 5 minutes
        return Date().timeIntervalSince(timestamp) > 300
    }
}

struct PostCard: View {
    let post: Post
    let postRepository: PostRepository
    var onCommentAdded: ((Comment) -> Void)? = nil
    var onCommentDeleted: ((String) -> Void)? = nil // commentId
    @StateObject private var userRepository = UserRepository()
    @StateObject private var contentModeration = ContentModerationService()
    @EnvironmentObject private var authManager: AuthManager
    @State private var showCommentSheet = false
    @State private var newComment = ""
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var authorProfileImageURL: String?
    @State private var showDeleteAlert = false
    @State private var selectedUser: User?
    @State private var currentPost: Post
    @State private var showReportSheet = false
    @State private var reportReason = ""
    @State private var showFullImage = false
    @State private var animatePop = false
    @State private var showLikesSheet = false
    @State private var likedUsers: [User] = []
    @State private var isLoadingLikes = false
    @State private var showEditSheet = false
    private let userCache = NSCache<NSString, UserCacheWrapper>()
    
    init(post: Post, postRepository: PostRepository, onCommentAdded: ((Comment) -> Void)? = nil, onCommentDeleted: ((String) -> Void)? = nil) {
        self.post = post
        self.postRepository = postRepository
        self.onCommentAdded = onCommentAdded
        self.onCommentDeleted = onCommentDeleted
        _currentPost = State(initialValue: post)
        
        // Initialize with cached profile image URL if available
        if let cachedURL = ProfileImageCache.shared.getProfileImage(for: post.authorId) {
            _authorProfileImageURL = State(initialValue: cachedURL)
        }
    }
    
    private var isLiked: Bool {
        guard let userId = authManager.currentUser?.id else { return false }
        return currentPost.likes.contains(userId)
    }
    
    private var isCurrentUser: Bool {
        currentPost.authorId == authManager.currentUser?.id
    }
    
    private func createAttributedContent() -> AttributedString {
        var attributed = AttributedString(currentPost.content)
        let urls = currentPost.content.detectURLs()
        
        for (url, range) in urls {
            if let attributedRange = Range(range, in: attributed) {
                attributed[attributedRange].foregroundColor = .blue
                attributed[attributedRange].underlineStyle = .single
                attributed[attributedRange].link = url
            }
        }
        
        return attributed
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                PostUserInfoView(
                    post: currentPost,
                    profileImageURL: authorProfileImageURL,
                    isCurrentUser: isCurrentUser,
                    onDelete: { showDeleteAlert = true },
                    onEdit: isCurrentUser ? { showEditSheet = true } : nil,
                    postRepository: postRepository
                )
                Text(createAttributedContent())
                    .font(.body)
                    .environment(\.openURL, OpenURLAction { url in
                        print("Opening URL: \(url)")
                        return .systemAction
                    })
                
                if let imageURL = currentPost.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxHeight: 250)
                            .clipped()
                            .cornerRadius(10)
                    } placeholder: {
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(maxHeight: 250)
                                .cornerRadius(10)
                            ProgressView()
                        }
                    }
                    .padding(.bottom, 4)
                    .allowsHitTesting(false)
                    .overlay(
                        Button(action: { withAnimation(.spring()) { showFullImage = true; animatePop = true } }) {
                            Color.clear
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showFullImage = true
                            animatePop = true
                        }
                    }
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        Task {
                            await loadLikedUsers()
                            showLikesSheet = true
                        }
                    }) {
                        Text("\(currentPost.likes.count) likes")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text("\(currentPost.comments.count) comments")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(currentPost.shareCount) shares")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                PostInteractionButtonsView(
                    post: currentPost,
                    isLiked: isLiked,
                    onLike: handleLike,
                    onComment: { showCommentSheet = true },
                    onShare: { showShareSheet = true }
                )
                
                PostCommentsView(
                    post: currentPost,
                    onViewAllComments: { showCommentSheet = true }
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1.3)
            )
            .padding(.horizontal, 2)
            .alert("Delete Post", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deletePost()
                }
            } message: {
                Text("Are you sure you want to delete this post? This action cannot be undone.")
            }
            .sheet(isPresented: $showCommentSheet, onDismiss: {
                // Reset comment state when sheet is dismissed
                newComment = ""
            }) {
                CommentsSheetView(
                    post: currentPost,
                    showSheet: $showCommentSheet,
                    newComment: $newComment,
                    onComment: handleComment,
                    postRepository: postRepository,
                    onCommentAdded: { comment in
                        currentPost.comments.append(comment)
                        onCommentAdded?(comment)
                    },
                    onCommentDeleted: { commentId in
                        currentPost.comments.removeAll { $0.id == commentId }
                        onCommentDeleted?(commentId)
                    }
                )
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [currentPost.content])
            }
            .sheet(isPresented: $showReportSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("Report Reason")) {
                            TextField("Enter reason for reporting", text: $reportReason)
                        }
                        
                        Section {
                            Button("Submit Report") {
                                submitReport()
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .navigationTitle("Report Post")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showReportSheet = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showLikesSheet) {
                NavigationView {
                    ZStack {
                        if isLoadingLikes {
                            ProgressView("Loading likes...")
                        } else if likedUsers.isEmpty {
                            Text("No likes yet")
                                .foregroundColor(.gray)
                        } else {
                            List(likedUsers) { user in
                                HStack {
                                    if let profileImageURL = user.profileImageURL,
                                       let url = URL(string: profileImageURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("\(user.firstName) \(user.lastName)")
                                            .font(.headline)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Likes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showLikesSheet = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditPostSheet(post: currentPost) { updatedContent in
                    guard let postId = currentPost.id else { return }
                    Task {
                        do {
                            try await postRepository.updatePostContent(postId: postId, newContent: updatedContent)
                            await MainActor.run {
                                currentPost.content = updatedContent
                            }
                        } catch {
                            await MainActor.run {
                                showError = true
                                errorMessage = "Failed to update post: \(error.localizedDescription)"
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
            .contextMenu {
                if !isCurrentUser {
                    Button(action: {
                        showReportSheet = true
                    }) {
                        Label("Report Post", systemImage: "exclamationmark.triangle")
                    }
                }
            }
            .task {
                if authorProfileImageURL == nil {
                    do {
                        let user = try await userRepository.getUser(withId: currentPost.authorId)
                        if let profileURL = user?.profileImageURL {
                            authorProfileImageURL = profileURL
                            ProfileImageCache.shared.setProfileImage(for: currentPost.authorId, url: profileURL)
                        }
                    } catch {
                        print("Error fetching user profile image: \(error.localizedDescription)")
                    }
                }
            }
            .onAppear {
                postRepository.startSinglePostListener(postId: post.id ?? "") { updatedPost in
                    if let post = updatedPost {
                        currentPost = post
                    }
                }
            }
            .onDisappear {
                postRepository.stopSinglePostListener(postId: post.id ?? "")
            }
            if showFullImage, let imageURL = currentPost.imageURL, let url = URL(string: imageURL) {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) { showFullImage = false; animatePop = false }
                    }
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .scaleEffect(animatePop ? 1.0 : 0.7)
                            .opacity(animatePop ? 1.0 : 0.0)
                            .animation(.spring(), value: animatePop)
                    } placeholder: {
                        ProgressView()
                    }
                    Button(action: { withAnimation(.spring()) { showFullImage = false; animatePop = false } }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .transition(.scale)
            }
        }
    }
    
    private func handleLike() {
        guard let userId = authManager.currentUser?.id else {
            Task { @MainActor in
                showError = true
                errorMessage = "You must be logged in to like posts"
            }
            return
        }
        
        Task {
            do {
                try await postRepository.toggleLike(postId: post.id ?? "", userId: userId)
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handleComment() {
        guard let currentUser = authManager.currentUser else {
            Task { @MainActor in
                showError = true
                errorMessage = "You must be logged in to comment"
            }
            return
        }
        
        let commentContent = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !commentContent.isEmpty else { return }
        
        // Extract mentions from the comment
        var mentions: [Mention] = []
        let words = commentContent.components(separatedBy: .whitespacesAndNewlines)
        var currentIndex = 0
        
        for word in words {
            if word.hasPrefix("@") {
                let userName = String(word.dropFirst())
                if let user = selectedUser {
                    let mention = Mention(
                        id: UUID().uuidString,
                        userId: user.id ?? "",
                        userName: userName,
                        range: currentIndex..<(currentIndex + word.count)
                    )
                    mentions.append(mention)
                }
            }
            currentIndex += word.count + 1 // +1 for the space
        }
        
        Task {
            do {
                let comment = try await postRepository.addComment(
                    postId: post.id ?? "",
                    content: commentContent,
                    authorId: currentUser.id ?? "",
                    authorName: "\(currentUser.firstName) \(currentUser.lastName)",
                    mentions: mentions
                )
                
                await MainActor.run {
                    onCommentAdded?(comment)
                    newComment = ""
                    showCommentSheet = false
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handleShare() {
        Task {
            do {
                try await postRepository.incrementShareCount(postId: post.id ?? "")
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func deletePost() {
        Task {
            do {
                try await postRepository.deletePost(postId: post.id ?? "")
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = "Failed to delete post: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func submitReport() {
        guard let currentUserId = authManager.currentUser?.id,
              let postId = currentPost.id else { return }
        
        Task {
            do {
                try await contentModeration.reportContent(
                    contentId: postId,
                    reportedBy: currentUserId,
                    reason: reportReason
                )
                
                await MainActor.run {
                    showReportSheet = false
                    reportReason = ""
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = "Failed to submit report: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadLikedUsers() async {
        isLoadingLikes = true
        likedUsers = []
        
        // First check cache for any users
        var cachedUsers: [User] = []
        var userIdsToFetch: [String] = []
        
        for userId in currentPost.likes {
            if let cachedWrapper = userCache.object(forKey: userId as NSString) {
                if !cachedWrapper.isExpired {
                    cachedUsers.append(cachedWrapper.user)
                } else {
                    userIdsToFetch.append(userId)
                }
            } else {
                userIdsToFetch.append(userId)
            }
        }
        
        // Update UI with cached users immediately
        if !cachedUsers.isEmpty {
            await MainActor.run {
                likedUsers = cachedUsers
            }
        }
        
        // If we have users to fetch, do it in batches
        if !userIdsToFetch.isEmpty {
            do {
                // Fetch users in batches of 10
                let batchSize = 10
                for i in stride(from: 0, to: userIdsToFetch.count, by: batchSize) {
                    let endIndex = min(i + batchSize, userIdsToFetch.count)
                    let batchUserIds = Array(userIdsToFetch[i..<endIndex])
                    
                    // Fetch batch of users
                    let batchUsers = try await withThrowingTaskGroup(of: User?.self) { group in
                        for userId in batchUserIds {
                            group.addTask {
                                try? await userRepository.getUser(withId: userId)
                            }
                        }
                        
                        var users: [User] = []
                        for try await user in group {
                            if let user = user {
                                users.append(user)
                            }
                        }
                        return users
                    }
                    
                    // Cache and update UI with batch results
                    for user in batchUsers {
                        if let userId = user.id {
                            userCache.setObject(UserCacheWrapper(user: user), forKey: userId as NSString)
                        }
                    }
                    
                    await MainActor.run {
                        likedUsers.append(contentsOf: batchUsers)
                    }
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = "Failed to load likes: \(error.localizedDescription)"
                }
            }
        }
        
        await MainActor.run {
            isLoadingLikes = false
        }
    }
}

// ShareSheet for sharing functionality
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PostDetailSheet: View {
    let postId: String
    @StateObject private var postRepository = PostRepository()
    @State private var post: Post? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading post...")
                    .padding()
            } else if let post = post {
                ScrollView {
                    PostCard(post: post, postRepository: postRepository)
                }
                .padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text("Post not found.")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .onAppear {
            fetchPost()
        }
    }

    private func fetchPost() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let document = try await postRepository.db.collection("posts").document(postId).getDocument()
                if let fetchedPost = try? document.data(as: Post.self) {
                    var postWithId = fetchedPost
                    postWithId.id = document.documentID
                    await MainActor.run {
                        self.post = postWithId
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Failed to decode post."
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
} 
