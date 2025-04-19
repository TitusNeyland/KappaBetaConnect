import Foundation
import FirebaseFirestore

class LineRepository: ObservableObject {
    private let db = Firestore.firestore()
    @Published var lines: [Line] = []
    
    func fetchLines() async throws {
        let snapshot = try await db.collection("lines").getDocuments()
        self.lines = try snapshot.documents.map { document in
            var line = try document.data(as: Line.self)
            line.id = document.documentID
            return line
        }
    }
    
    func getLine(withId id: String) async throws -> Line? {
        let document = try await db.collection("lines").document(id).getDocument()
        guard document.exists else { return nil }
        var line = try document.data(as: Line.self)
        line.id = document.documentID
        return line
    }
    
    func createLine(_ line: Line) async throws {
        let docRef = try db.collection("lines").addDocument(from: line)
        print("Line created with ID: \(docRef.documentID)")
    }
    
    // Add sample data for testing
    func addSampleLine() async throws {
        let sampleLine = Line(
            line_name: "The 12 Invaders",
            semester: "Fall",
            year: 2021,
            members: [
                LineMember(name: "Nathan D. Mosley", alias: "Bra1n PHreeze", number: 1),
                LineMember(name: "Titus A. Neyland", alias: "InDEUCEd Intent", number: 2),
                LineMember(name: "Tyler J. Woodberry", alias: "UnPHorseen PHorc3", number: 3),
                LineMember(name: "Zachary J. Mikell", alias: "Disclos4r", number: 4),
                LineMember(name: "Trey K. O'Neal", alias: "PHInatical Intelle5t", number: 5),
                LineMember(name: "Chris R. Kee", alias: "Prophetic PHro6t", number: 6),
                LineMember(name: "Peyton O. Brown", alias: "Ar7ic Menace", number: 7),
                LineMember(name: "Tyriq J. Mitchell", alias: "Wint8r Soldier", number: 8),
                LineMember(name: "Rucell Harris Jr.", alias: "PHrozen Ten9city", number: 9),
                LineMember(name: "Frederick D. McCollum Jr.", alias: "Cold Assert10n", number: 10),
                LineMember(name: "Josh B. Bailey", alias: "S1lent N1ght", number: 11),
                LineMember(name: "Johnny E. Wilson III", alias: "PHIna1 Produc2", number: 12)
            ]
        )
        
        try await createLine(sampleLine)
    }
} 
