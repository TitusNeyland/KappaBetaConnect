import Foundation
import FirebaseFirestore
import FirebaseStorage

class PostRepository: ObservableObject {
    let db = Firestore.firestore()
    private let storage = Storage.storage()
    @Published var posts: [Post] = []
    private var postsListener: ListenerRegistration?
    private var postListeners: [String: ListenerRegistration] = [:]
    private var blockedUsers: [String] = []
    
    init() {
        startPostsListener()
    }
    
    deinit {
        // Clean up listeners
        postsListener?.remove()
        postListeners.values.forEach { $0.remove() }
    }
    
    func updateBlockedUsers(_ blockedUsers: [String]) {
        Task { @MainActor in
            self.blockedUsers = blockedUsers
            // Refresh posts to apply new block list
            try? await fetchPosts()
        }
    }
    
    private func startPostsListener() {
        postsListener = db.collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for post updates: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot else { return }
                
                let fetchedPosts = snapshot.documents.compactMap { document -> Post? in
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
                
                Task { @MainActor in
                    self.posts = filteredPosts
                }
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
        let snapshot = try await db.collection("posts")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        let fetchedPosts = try snapshot.documents.compactMap { document in
            var post = try document.data(as: Post.self)
            post.id = document.documentID
            return post
        }
        
        // Filter out posts from blocked users
        let filteredPosts = fetchedPosts.filter { post in
            !self.blockedUsers.contains(post.authorId)
        }
        
        await MainActor.run {
            self.posts = filteredPosts
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
    
    func createPost(content: String, authorId: String, authorName: String, image: UIImage? = nil) async throws {
        var imageURL: String? = nil
        if let image = image {
            imageURL = try await uploadImage(image, authorId: authorId)
        }
        let post = Post(
            content: content,
            authorId: authorId,
            authorName: authorName,
            timestamp: Date(),
            likes: [],
            comments: [],
            shareCount: 0,
            imageURL: imageURL
        )
        _ = try await db.collection("posts").addDocument(from: post)
    }
    
    private func uploadImage(_ image: UIImage, authorId: String) async throws -> String {
        let resizedImage = image.resizedTo(maxDimension: 1080)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
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
            imageURL: imageURL
        )
        
        let postRef = db.collection("posts").document(postId)
        try await postRef.updateData([
            "comments": FieldValue.arrayUnion([try Firestore.Encoder().encode(comment)])
        ])
        
        return comment
    }
    
    private func uploadCommentImage(_ image: UIImage, authorId: String) async throws -> String {
        let resizedImage = image.resizedTo(maxDimension: 1080)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
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
        // The listener will handle updating the posts array
    }
    
    // Update post content
    func updatePostContent(postId: String, newContent: String) async throws {
        let postRef = db.collection("posts").document(postId)
        try await postRef.updateData(["content": newContent])
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
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.7)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
} 
