import Foundation
import FirebaseFirestore
import FirebaseStorage

class PostRepository: ObservableObject {
    let db = Firestore.firestore()
    private let storage = Storage.storage()
    @Published var posts: [Post] = []
    @Published var isLoadingMore = false
    @Published var hasMorePosts = true
    @Published var initialLoading = true
    private var postListeners: [String: ListenerRegistration] = [:]
    private var blockedUsers: [String] = []
    private var lastDocument: DocumentSnapshot?
    private let postsPerPage = 3
    // --- Upload state ---
    @Published var isUploadingPost: Bool = false
    @Published var uploadStatusMessage: String? = nil
    
    init() {}
    
    deinit {
        // Clean up listeners for single post listeners
        postListeners.values.forEach { $0.remove() }
    }
    
    func updateBlockedUsers(_ blockedUsers: [String]) {
        Task { @MainActor in
            self.blockedUsers = blockedUsers
            // Refresh posts to apply new block list
            try? await fetchPosts()
        }
    }
    
    func startSinglePostListener(postId: String, completion: @escaping (Post?) -> Void) {
        // Remove existing listener for this post if any
        postListeners[postId]?.remove()
        
        // Start new listener
        let listener = db.collection("posts").document(postId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening for post updates: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot else {
                    completion(nil)
                    return
                }
                
                do {
                    var post = try document.data(as: Post.self)
                    post.id = document.documentID
                    completion(post)
                } catch {
                    print("Error decoding post: \(error.localizedDescription)")
                    print("Raw data for post \(document.documentID): \(document.data())")
                    completion(nil)
                }
            }
        
        postListeners[postId] = listener
    }
    
    func stopSinglePostListener(postId: String) {
        postListeners[postId]?.remove()
        postListeners.removeValue(forKey: postId)
    }
    
    func fetchPosts() async throws {
        print("Starting fetchPosts")
        // Reset pagination state
        await MainActor.run {
            self.lastDocument = nil
            self.hasMorePosts = true
            self.initialLoading = true
        }
        let snapshot = try await db.collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: postsPerPage)
            .getDocuments()
        let lastDoc = snapshot.documents.last
        let fetchedPosts = try snapshot.documents.compactMap { document in
            print("Attempting to decode post with ID: \(document.documentID)")
            print("Raw post data: \(document.data())")
            do {
                var post = try document.data(as: Post.self)
                post.id = document.documentID
                return post
            } catch {
                print("Error decoding post: \(error.localizedDescription)")
                print("Raw data for post \(document.documentID): \(document.data())")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Missing key: \(key.stringValue), context: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: expected \(type), context: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("Value not found: expected \(type), context: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                return nil
            }
        }
        // Filter out posts from blocked users
        let filteredPosts = fetchedPosts.filter { post in
            !self.blockedUsers.contains(post.authorId)
        }
        await MainActor.run {
            self.posts = filteredPosts
            self.hasMorePosts = !(snapshot.documents.isEmpty)
            self.lastDocument = lastDoc
            self.initialLoading = false
            print("Finished fetchPosts, posts count: \(self.posts.count)")
        }
    }
    
    func loadMorePosts() async throws {
        print("Starting loadMorePosts")
        var shouldLoad = false
        await MainActor.run {
            shouldLoad = !self.isLoadingMore && self.hasMorePosts && self.lastDocument != nil
            if shouldLoad {
                self.isLoadingMore = true
            }
        }
        guard shouldLoad, let lastDocument = self.lastDocument else { return }
        let snapshot = try await db.collection("posts")
            .order(by: "timestamp", descending: true)
            .start(afterDocument: lastDocument)
            .limit(to: postsPerPage)
            .getDocuments()
        let newLastDoc = snapshot.documents.last
        let fetchedPosts = try snapshot.documents.compactMap { document in
            do {
                var post = try document.data(as: Post.self)
                post.id = document.documentID
                return post
            } catch {
                print("Error decoding post: \(error.localizedDescription)")
                return nil
            }
        }
        // Filter out posts from blocked users
        let filteredPosts = fetchedPosts.filter { post in
            !self.blockedUsers.contains(post.authorId)
        }
        await MainActor.run {
            self.posts.append(contentsOf: filteredPosts)
            self.hasMorePosts = !(snapshot.documents.isEmpty)
            self.lastDocument = newLastDoc
            self.isLoadingMore = false
            print("Finished loadMorePosts, posts count: \(self.posts.count)")
        }
    }
    
    // Fetch with timeout for debugging freezes
    func fetchPostsWithTimeout() async {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await self.fetchPosts()
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: 10 * 1_000_000_000) // 10 seconds
                    throw NSError(domain: "Timeout", code: 1)
                }
                try await group.next()
                group.cancelAll()
            }
        } catch {
            await MainActor.run {
                self.initialLoading = false
                print("fetchPostsWithTimeout error: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchPostsByAuthor(authorId: String) async throws -> [Post] {
        let snapshot = try await db.collection("posts")
            .whereField("authorId", isEqualTo: authorId)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            var post = try document.data(as: Post.self)
            post.id = document.documentID
            return post
        }
    }
    
    func fetchPost(postId: String) async throws {
        let document = try await db.collection("posts").document(postId).getDocument()
        guard var updatedPost = try? document.data(as: Post.self) else { return }
        updatedPost.id = document.documentID
        
        await MainActor.run {
            // Update the specific post in the posts array
            if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                self.posts[index] = updatedPost
            }
        }
    }
    
    func createPost(content: String, authorId: String, authorName: String, images: [UIImage] = []) async throws {
        await MainActor.run {
            self.isUploadingPost = true
            self.uploadStatusMessage = "Uploading post..."
        }
        var imageURLs: [String] = []
        do {
            // Upload up to 4 images
            for image in images.prefix(4) {
                if let imageURL = try? await uploadImage(image, authorId: authorId) {
                    imageURLs.append(imageURL)
                }
            }
            let post = Post(
                content: content,
                authorId: authorId,
                authorName: authorName,
                timestamp: Date(),
                likes: [],
                comments: [],
                shareCount: 0,
                imageURLs: imageURLs
            )
            let ref = try await db.collection("posts").addDocument(from: post)
            // Fetch the post with its Firestore ID and insert at the top of the feed
            let doc = try await ref.getDocument()
            if var newPost = try? doc.data(as: Post.self) {
                newPost.id = doc.documentID
                await MainActor.run {
                    self.posts.insert(newPost, at: 0)
                }
            }
            await MainActor.run {
                self.isUploadingPost = false
                self.uploadStatusMessage = "Post uploaded!"
            }
        } catch {
            await MainActor.run {
                self.isUploadingPost = false
                self.uploadStatusMessage = "Failed to upload post."
            }
            throw error
        }
    }
    
    private func uploadImage(_ image: UIImage, authorId: String) async throws -> String {
        let resizedImage = image.resizedTo(maxDimension: 2048)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.95) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        let imageID = UUID().uuidString
        let ref = storage.reference().child("post_images/")
            .child("\(authorId)_\(imageID).jpg")
        let _ = try await ref.putDataAsync(imageData)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
    
    func toggleLike(postId: String, userId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        let postDoc = try await postRef.getDocument()
        guard var post = try? postDoc.data(as: Post.self) else { return }
        
        if post.likes.contains(userId) {
            try await postRef.updateData([
                "likes": FieldValue.arrayRemove([userId])
            ])
        } else {
            try await postRef.updateData([
                "likes": FieldValue.arrayUnion([userId])
            ])
        }
    }
    
    @discardableResult
    func addComment(postId: String, content: String, authorId: String, authorName: String, mentions: [Mention] = [], image: UIImage? = nil) async throws -> Comment {
        var imageURL: String? = nil
        if let image = image {
            imageURL = try await uploadCommentImage(image, authorId: authorId)
        }
        
        let comment = Comment(
            id: UUID().uuidString,
            content: content,
            authorId: authorId,
            authorName: authorName,
            timestamp: Date(),
            mentions: mentions,
            imageURL: imageURL,
            replies: [],
            likes: []
        )
        
        let postRef = db.collection("posts").document(postId)
        try await postRef.updateData([
            "comments": FieldValue.arrayUnion([try Firestore.Encoder().encode(comment)])
        ])
        
        return comment
    }
    
    private func uploadCommentImage(_ image: UIImage, authorId: String) async throws -> String {
        let resizedImage = image.resizedTo(maxDimension: 2048)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.95) else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        let imageID = UUID().uuidString
        let ref = storage.reference().child("comment_images/")
            .child("\(authorId)_\(imageID).jpg")
        let _ = try await ref.putDataAsync(imageData)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
    
    func deleteComment(postId: String, commentId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        let postDoc = try await postRef.getDocument()
        guard var post = try? postDoc.data(as: Post.self) else { return }
        
        // Remove the comment from the array
        post.comments.removeAll { $0.id == commentId }
        
        // Update the entire comments array
        try await postRef.updateData([
            "comments": post.comments.map { try Firestore.Encoder().encode($0) }
        ])
    }
    
    func incrementShareCount(postId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        
        try await db.runTransaction { transaction, errorPointer in
            do {
                let postDoc = try transaction.getDocument(postRef)
                guard var post = try? postDoc.data(as: Post.self) else { return nil }
                
                post.shareCount += 1
                try transaction.setData(from: post, forDocument: postRef)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
    
    func deletePost(postId: String) async throws {
        try await db.collection("posts").document(postId).delete()
        await MainActor.run {
            self.posts.removeAll { $0.id == postId }
        }
    }
    
    // Update post content
    func updatePostContent(postId: String, newContent: String) async throws {
        let postRef = db.collection("posts").document(postId)
        try await postRef.updateData(["content": newContent])
    }
    
    // Add a reply to a comment
    @discardableResult
    func addReplyToComment(postId: String, parentCommentId: String, content: String, authorId: String, authorName: String, mentions: [Mention] = [], image: UIImage? = nil) async throws -> Comment? {
        var imageURL: String? = nil
        if let image = image {
            imageURL = try await uploadCommentImage(image, authorId: authorId)
        }
        
        let reply = Comment(
            id: UUID().uuidString,
            content: content,
            authorId: authorId,
            authorName: authorName,
            timestamp: Date(),
            mentions: mentions,
            imageURL: imageURL,
            replies: [],
            likes: []
        )
        
        let postRef = db.collection("posts").document(postId)
        let postDoc = try await postRef.getDocument()
        guard var post = try? postDoc.data(as: Post.self) else { return nil }
        
        // Find the parent comment and append the reply
        if let idx = post.comments.firstIndex(where: { $0.id == parentCommentId }) {
            post.comments[idx].replies.append(reply)
            // Update the entire comments array
            try await postRef.updateData([
                "comments": post.comments.map { try Firestore.Encoder().encode($0) }
            ])
            return reply
        }
        return nil
    }
    
    // Delete a reply from a comment
    func deleteReply(postId: String, parentCommentId: String, replyId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        let postDoc = try await postRef.getDocument()
        guard var post = try? postDoc.data(as: Post.self) else { return }
        // Find the parent comment
        if let idx = post.comments.firstIndex(where: { $0.id == parentCommentId }) {
            // Remove the reply from the replies array
            post.comments[idx].replies.removeAll { $0.id == replyId }
            // Update the entire comments array
            try await postRef.updateData([
                "comments": post.comments.map { try Firestore.Encoder().encode($0) }
            ])
        }
    }
    
    // Toggle like on a comment
    func toggleCommentLike(postId: String, commentId: String, userId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        let postDoc = try await postRef.getDocument()
        guard var post = try? postDoc.data(as: Post.self) else { return }
        
        // Find the comment and toggle the like
        if let commentIndex = post.comments.firstIndex(where: { $0.id == commentId }) {
            var comment = post.comments[commentIndex]
            if comment.likes.contains(userId) {
                comment.likes.removeAll { $0 == userId }
            } else {
                comment.likes.append(userId)
            }
            post.comments[commentIndex] = comment
            
            // Update the entire comments array
            try await postRef.updateData([
                "comments": post.comments.map { try Firestore.Encoder().encode($0) }
            ])
        }
    }
    
    // Toggle like on a reply (nested comment)
    func toggleReplyLike(postId: String, parentCommentId: String, replyId: String, userId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        let postDoc = try await postRef.getDocument()
        guard var post = try? postDoc.data(as: Post.self) else { return }
        
        // Find the parent comment
        if let parentIndex = post.comments.firstIndex(where: { $0.id == parentCommentId }) {
            var parentComment = post.comments[parentIndex]
            // Find the reply
            if let replyIndex = parentComment.replies.firstIndex(where: { $0.id == replyId }) {
                var reply = parentComment.replies[replyIndex]
                if reply.likes.contains(userId) {
                    reply.likes.removeAll { $0 == userId }
                } else {
                    reply.likes.append(userId)
                }
                parentComment.replies[replyIndex] = reply
                post.comments[parentIndex] = parentComment
                // Update the entire comments array
                try await postRef.updateData([
                    "comments": post.comments.map { try Firestore.Encoder().encode($0) }
                ])
            }
        }
    }
}

// Helper to resize UIImage
extension UIImage {
    func resizedTo(maxDimension: CGFloat) -> UIImage {
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        if size.width <= maxDimension && size.height <= maxDimension {
            return self // No resizing needed
        }
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0) // Best quality
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
} 
