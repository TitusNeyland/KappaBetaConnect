import SwiftUI

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
                newPostContent = ""
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
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                )
            
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

// PostCard View
struct PostCard: View {
    let post: Post
    let postRepository: PostRepository
    @EnvironmentObject private var authManager: AuthManager
    @State private var showCommentSheet = false
    @State private var newComment = ""
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var isLiked: Bool {
        guard let userId = authManager.currentUser?.id else { return false }
        return post.likes.contains(userId)
    }
    
    private var recentComments: [Comment] {
        Array(post.comments.suffix(2).reversed())
    }
    
    private var allComments: [Comment] {
        Array(post.comments.reversed())
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
            // User info
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.headline)
                    Text(post.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Menu {
                    if post.authorId == authManager.currentUser?.id {
                        Button(role: .destructive, action: {}) {
                            Label("Delete", systemImage: "trash")
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
            
            // Post content with clickable links
            Text(createAttributedContent())
                .font(.body)
                .environment(\.openURL, OpenURLAction { url in
                    print("Opening URL: \(url)")
                    return .systemAction
                })
            
            // Interaction counts
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
            
            // Interaction buttons
            HStack(spacing: 20) {
                Button(action: {
                    handleLike()
                }) {
                    HStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                        Text("Like")
                    }
                    .foregroundColor(isLiked ? .red : .gray)
                }
                
                Button(action: {
                    showCommentSheet = true
                }) {
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("Comment")
                    }
                    .foregroundColor(.gray)
                }
                
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .foregroundColor(.gray)
                }
            }
            
            // Recent comments (show last 2)
            if !post.comments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recentComments) { comment in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(comment.authorName)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(comment.content)
                                .font(.caption)
                            Text(comment.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if post.comments.count > 2 {
                        Button(action: {
                            showCommentSheet = true
                        }) {
                            Text("View all \(post.comments.count) comments")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showCommentSheet) {
            NavigationView {
                VStack {
                    // Existing comments
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(allComments) { comment in
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
                    
                    // New comment input
                    HStack {
                        TextField("Add a comment...", text: $newComment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            handleComment()
                        }) {
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
                            showCommentSheet = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [post.content])
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
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