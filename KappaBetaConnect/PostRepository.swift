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
        
        // Update the specific post in the posts array
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index] = updatedPost
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
                
                // Update local posts array
                if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                    self.posts[index].likes = post.likes
                }
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
    
    @discardableResult
    func addComment(postId: String, content: String, authorId: String, authorName: String) async throws -> Comment {
        let comment = Comment(
            id: UUID().uuidString,
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
                
                // Update local posts array
                if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                    self.posts[index].comments = post.comments
                }
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        
        return comment
    }
    
    func deleteComment(postId: String, commentId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        
        try await db.runTransaction { transaction, errorPointer in
            do {
                let postDoc = try transaction.getDocument(postRef)
                guard var post = try? postDoc.data(as: Post.self) else { return nil }
                
                // Remove the comment with matching ID
                post.comments.removeAll { $0.id == commentId }
                
                try transaction.setData(from: post, forDocument: postRef)
                
                // Update local posts array
                if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                    self.posts[index].comments = post.comments
                }
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
    
    func incrementShareCount(postId: String) async throws {
        let postRef = db.collection("posts").document(postId)
        
        try await db.runTransaction { transaction, errorPointer in
            do {
                let postDoc = try transaction.getDocument(postRef)
                guard var post = try? postDoc.data(as: Post.self) else { return nil }
                
                post.shareCount += 1
                try transaction.setData(from: post, forDocument: postRef)
                
                // Update local posts array
                if let index = self.posts.firstIndex(where: { $0.id == postId }) {
                    self.posts[index].shareCount = post.shareCount
                }
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
    
    func deletePost(postId: String) async throws {
        // Delete the post from Firestore
        try await db.collection("posts").document(postId).delete()
        
        // Remove the post from the local posts array
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts.remove(at: index)
        }
    }
} 
