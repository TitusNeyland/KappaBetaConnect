import Foundation
import FirebaseFirestore

class LineRepository: ObservableObject {
    private let db = Firestore.firestore()
    @Published var lines: [Line] = []
    
    func fetchLines() async throws {
        let snapshot = try await db.collection("lines").getDocuments()
        let fetchedLines = try snapshot.documents.map { document in
            var line = try document.data(as: Line.self)
            line.id = document.documentID
            return line
        }
        await MainActor.run {
            self.lines = fetchedLines
        }
    }
    
    func getLine(withId id: String) async throws -> Line? {
        let document = try await db.collection("lines").document(id).getDocument()
        guard document.exists else { return nil }
        var line = try document.data(as: Line.self)
        line.id = document.documentID
        return line
    }
    
    func findLine(semester: String, year: Int) async throws -> Line? {
        let snapshot = try await db.collection("lines")
            .whereField("semester", isEqualTo: semester)
            .whereField("year", isEqualTo: year)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        var line = try document.data(as: Line.self)
        line.id = document.documentID
        return line
    }
    
    func getLineMemberDetails(line: Line, lineNumber: Int) -> (alias: String?, name: String)? {
        guard let member = line.members.first(where: { member in member.number == lineNumber }) else {
            return nil
        }
        return (alias: member.alias, name: member.name)
    }
    
    func createLine(_ line: Line) async throws {
        let docRef = try db.collection("lines").addDocument(from: line)
        print("Line created with ID: \(docRef.documentID)")
    }
    
    func fetchMostRecentLine() async throws -> Line? {
        let snapshot = try await db.collection("lines")
            .order(by: "year", descending: true)
            .getDocuments()
        
        // Get all lines and sort them by year and semester
        let allLines = try snapshot.documents.compactMap { document -> Line? in
            var line = try document.data(as: Line.self)
            line.id = document.documentID
            return line
        }
        
        // Sort lines by year and semester
        let sortedLines = allLines.sorted { line1, line2 in
            if line1.year != line2.year {
                return line1.year > line2.year
            }
            // If years are equal, Fall comes before Spring
            return line1.semester == "Fall" && line2.semester == "Spring"
        }
        
        return sortedLines.first
    }
} 
