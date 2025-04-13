import Foundation
import FirebaseFirestore

class PostRepository: ObservableObject {
    private let db = Firestore.firestore()
    @Published var posts: [Post] = []
    
    func fetchPosts() async throws {
        let snapshot = try await db.collection("posts")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        self.posts = try snapshot.documents.compactMap { document in
            var post = try document.data(as: Post.self)
            post.id = document.documentID
            return post
        }
    }
    
    func createPost(content: String, authorId: String, authorName: String) async throws {
        let post = Post(
            content: content,
            authorId: authorId,
            authorName: authorName,
            timestamp: Date(),
            likes: [],
            comments: [],
            shareCount: 0
        )
        
        _ = try db.collection("posts").addDocument(from: post)
        try await fetchPosts() // Refresh posts after creating new one
    }
    
    func toggleLike(postId: String, userId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        
        try await db.runTransaction { transaction, errorPointer in
            do {
                let postDoc = try transaction.getDocument(postRef)
                guard var post = try? postDoc.data(as: Post.self) else { return nil }
                
                if post.likes.contains(userId) {
                    post.likes.removeAll { $0 == userId }
                } else {
                    post.likes.append(userId)
                }
                
                try transaction.setData(from: post, forDocument: postRef)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        
        try await fetchPosts() // Refresh posts after updating
    }
    
    func addComment(postId: String, content: String, authorId: String, authorName: String) async throws {
        let comment = Comment(
            content: content,
            authorId: authorId,
            authorName: authorName,
            timestamp: Date()
        )
        
        let postRef = db.collection("posts").document(postId)
        
        try await db.runTransaction { transaction, errorPointer in
            do {
                let postDoc = try transaction.getDocument(postRef)
                guard var post = try? postDoc.data(as: Post.self) else { return nil }
                
                post.comments.append(comment)
                try transaction.setData(from: post, forDocument: postRef)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        
        try await fetchPosts() // Refresh posts after updating
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
        
        try await fetchPosts() // Refresh posts after updating
    }
} 
