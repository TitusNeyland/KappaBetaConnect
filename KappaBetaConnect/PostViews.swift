import SwiftUI

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

// Create Post Sheet View
struct CreatePostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var postRepository: PostRepository
    @EnvironmentObject private var authManager: AuthManager
    @Binding var showError: Bool
    @Binding var errorMessage: String
    @State private var newPostContent = ""
    
    private let maxCharacterCount = 500
    
    private var detectedLinks: [URL] {
        newPostContent.detectURLs().map { $0.url }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // User info header
                if let currentUser = authManager.currentUser {
                    UserHeaderView(user: currentUser)
                }
                
                // Post content editor
                PostEditorView(content: $newPostContent)
                
                // Link previews
                if !detectedLinks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Links detected:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        ForEach(detectedLinks, id: \.absoluteString) { url in
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Text(url.absoluteString)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Character count and guidelines
                PostGuidelinesView(contentCount: newPostContent.count, maxCount: maxCharacterCount)
                
                Spacer()
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        newPostContent = ""
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        createPost()
                    }
                    .disabled(isPostButtonDisabled)
                    .font(.headline)
                    .foregroundColor(isPostButtonDisabled ? .gray : .black)
                }
            }
        }
    }
    
    private var isPostButtonDisabled: Bool {
        newPostContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        newPostContent.count > maxCharacterCount
    }
    
    private func createPost() {
        guard let currentUser = authManager.currentUser else {
            showError = true
            errorMessage = "You must be logged in to create a post"
            return
        }
        
        let content = newPostContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty && content.count <= maxCharacterCount else { return }
        
        Task {
            do {
                try await postRepository.createPost(
                    content: content,
                    authorId: currentUser.id ?? "",
                    authorName: "\(currentUser.firstName) \(currentUser.lastName)"
                )
                dismiss()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct UserHeaderView: View {
    let user: User
    
    var body: some View {
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.headline)
                Text("Posting to Feed")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct FocusedTextEditor: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.text = text.isEmpty ? placeholder : text
        textView.textColor = text.isEmpty ? .placeholderText : .label
        textView.becomeFirstResponder() // Automatically show keyboard
        
        // Prevent keyboard from being dismissed
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .none
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if text != uiView.text {
            uiView.text = text
        }
        if text.isEmpty && !uiView.isFirstResponder {
            uiView.text = placeholder
            uiView.textColor = .placeholderText
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: FocusedTextEditor
        
        init(_ parent: FocusedTextEditor) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if parent.text.isEmpty {
                textView.text = ""
                textView.textColor = .label
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if parent.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
        }
    }
}

struct PostEditorView: View {
    @Binding var content: String
    
    var body: some View {
        FocusedTextEditor(text: $content, placeholder: "What's on your mind?")
            .frame(minHeight: 150)
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal)
    }
}

struct PostGuidelinesView: View {
    let contentCount: Int
    let maxCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(contentCount)/\(maxCount)")
                    .font(.caption)
                    .foregroundColor(
                        contentCount > Int(Double(maxCount) * 0.8)
                        ? (contentCount > maxCount ? .red : .orange)
                        : .gray
                    )
                
                Spacer()
            }
            
            if contentCount > 0 {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                    Text("Your post will be visible to all fraternity members")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }
}

// User Info Section
struct PostUserInfoView: View {
    let post: Post
    let profileImageURL: String?
    let isCurrentUser: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            if let profileImageURL = profileImageURL,
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

            VStack(alignment: .leading, spacing: 2) {
                Text(post.authorName)
                    .font(.headline)
                Text(post.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Menu {
                if isCurrentUser {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Post", systemImage: "trash")
                    }
                } else {
                    Button(action: {}) {
                        Label("Report", systemImage: "flag")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
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
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(post.comments.reversed()) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(comment.authorName)
                                        .font(.headline)
                                    Spacer()
                                    Text(comment.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Text(comment.content)
                                    .font(.body)
                            }
                            .padding(.horizontal)
                            Divider()
                        }
                    }
                    .padding(.vertical)
                }
                
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: onComment) {
                        Text("Post")
                            .fontWeight(.medium)
                    }
                    .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showSheet = false
                    }
                }
            }
        }
    }
}

// PostCard View
struct PostCard: View {
    let post: Post
    let postRepository: PostRepository
    @StateObject private var userRepository = UserRepository()
    @EnvironmentObject private var authManager: AuthManager
    @State private var showCommentSheet = false
    @State private var newComment = ""
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var authorProfileImageURL: String?
    @State private var showDeleteAlert = false
    
    private var isLiked: Bool {
        guard let userId = authManager.currentUser?.id else { return false }
        return post.likes.contains(userId)
    }
    
    private var isCurrentUser: Bool {
        post.authorId == authManager.currentUser?.id
    }
    
    private func createAttributedContent() -> AttributedString {
        var attributed = AttributedString(post.content)
        let urls = post.content.detectURLs()
        
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
        VStack(alignment: .leading, spacing: 12) {
            PostUserInfoView(
                post: post,
                profileImageURL: authorProfileImageURL,
                isCurrentUser: isCurrentUser,
                onDelete: { showDeleteAlert = true }
            )
            
            Text(createAttributedContent())
                .font(.body)
                .environment(\.openURL, OpenURLAction { url in
                    print("Opening URL: \(url)")
                    return .systemAction
                })
            
            HStack(spacing: 20) {
                Text("\(post.likes.count) likes")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(post.comments.count) comments")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(post.shareCount) shares")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            PostInteractionButtonsView(
                post: post,
                isLiked: isLiked,
                onLike: handleLike,
                onComment: { showCommentSheet = true },
                onShare: { showShareSheet = true }
            )
            
            PostCommentsView(
                post: post,
                onViewAllComments: { showCommentSheet = true }
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .alert("Delete Post", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deletePost()
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .sheet(isPresented: $showCommentSheet) {
            CommentsSheetView(
                post: post,
                showSheet: $showCommentSheet,
                newComment: $newComment,
                onComment: handleComment
            )
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [post.content])
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            do {
                let user = try await userRepository.getUser(withId: post.authorId)
                authorProfileImageURL = user?.profileImageURL
            } catch {
                print("Error fetching user profile image: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleLike() {
        guard let userId = authManager.currentUser?.id else {
            showError = true
            errorMessage = "You must be logged in to like posts"
            return
        }
        
        Task {
            do {
                try await postRepository.toggleLike(postId: post.id ?? "", userId: userId)
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func handleComment() {
        guard let currentUser = authManager.currentUser else {
            showError = true
            errorMessage = "You must be logged in to comment"
            return
        }
        
        let commentContent = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !commentContent.isEmpty else { return }
        
        Task {
            do {
                try await postRepository.addComment(
                    postId: post.id ?? "",
                    content: commentContent,
                    authorId: currentUser.id ?? "",
                    authorName: "\(currentUser.firstName) \(currentUser.lastName)"
                )
                
                newComment = ""
                showCommentSheet = false
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func handleShare() {
        Task {
            do {
                try await postRepository.incrementShareCount(postId: post.id ?? "")
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func deletePost() {
        Task {
            do {
                try await postRepository.deletePost(postId: post.id ?? "")
            } catch {
                showError = true
                errorMessage = "Failed to delete post: \(error.localizedDescription)"
            }
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