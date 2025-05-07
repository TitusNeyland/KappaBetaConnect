import Foundation
import FirebaseFirestore
import Combine
import MessageUI

class ContentModerationService: ObservableObject {
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    private let postsCollection = "posts"
    private let adminEmail = "titusaneyland@gmail.com"
    
    @Published var isProcessing = false
    @Published var error: Error?
    
    // Report content
    func reportContent(contentId: String, reportedBy: String, reason: String) async throws {
        isProcessing = true
        defer { isProcessing = false }
        
        // Get user's name
        let userDoc = try await db.collection(usersCollection).document(reportedBy).getDocument()
        guard let userData = userDoc.data(),
              let firstName = userData["firstName"] as? String,
              let lastName = userData["lastName"] as? String else {
            throw NSError(domain: "ContentModerationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user information"])
        }
        
        let reportData: [String: Any] = [
            "contentId": contentId,
            "reportedBy": reportedBy,
            "reporterName": "\(firstName) \(lastName)",
            "reason": reason,
            "timestamp": Date(),
            "status": "pending"
        ]
        
        // Store in Firestore
        try await db.collection("reports").addDocument(data: reportData)
        
        // Add to user's reported content
        try await db.collection(usersCollection).document(reportedBy).updateData([
            "reportedContent": FieldValue.arrayUnion([contentId])
        ])
        
        // Send email report
        await sendEmailReport(contentId: contentId, reportedBy: "\(firstName) \(lastName)", reason: reason)
    }
    
    private func sendEmailReport(contentId: String, reportedBy: String, reason: String) async {
        let subject = "Content Report - Kappa Beta Connect"
        let body = """
        A new content report has been submitted:
        
        Content ID: \(contentId)
        Reported By: \(reportedBy)
        Reason: \(reason)
        Timestamp: \(Date())
        
        Please review this content and take appropriate action.
        """
        
        if let url = createEmailURL(to: adminEmail, subject: subject, body: body) {
            await MainActor.run {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func createEmailURL(to: String, subject: String, body: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
        return URL(string: urlString)
    }
    
    // Block user
    func blockUser(userId: String, blockedUserId: String) async throws {
        isProcessing = true
        defer { isProcessing = false }
        
        try await db.collection(usersCollection).document(userId).updateData([
            "blockedUsers": FieldValue.arrayUnion([blockedUserId])
        ])
    }
    
    // Unblock user
    func unblockUser(userId: String, blockedUserId: String) async throws {
        isProcessing = true
        defer { isProcessing = false }
        
        try await db.collection(usersCollection).document(userId).updateData([
            "blockedUsers": FieldValue.arrayRemove([blockedUserId])
        ])
    }
    
    // Get blocked users
    func getBlockedUsers(userId: String) async throws -> [String] {
        isProcessing = true
        defer { isProcessing = false }
        
        let document = try await db.collection(usersCollection).document(userId).getDocument()
        return document.data()?["blockedUsers"] as? [String] ?? []
    }
    
    // Check if content is reported
    func isContentReported(contentId: String) async throws -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        
        let snapshot = try await db.collection("reports")
            .whereField("contentId", isEqualTo: contentId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    // Remove reported content
    func removeReportedContent(contentId: String) async throws {
        isProcessing = true
        defer { isProcessing = false }
        
        // Remove the content
        try await db.collection(postsCollection).document(contentId).delete()
        
        // Update report status
        let snapshot = try await db.collection("reports")
            .whereField("contentId", isEqualTo: contentId)
            .getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.updateData([
                "status": "resolved",
                "resolvedAt": Date()
            ])
        }
    }
} 