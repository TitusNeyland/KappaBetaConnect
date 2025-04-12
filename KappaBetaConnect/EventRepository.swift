import Foundation
import FirebaseFirestore

class EventRepository: ObservableObject {
    private let db = Firestore.firestore()
    private let eventsCollection = "events"
    
    @Published var events: [Event] = []
    
    init() {
        // Set up real-time listener for events
        db.collection(eventsCollection)
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching events: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.events = documents.compactMap { document in
                    try? document.data(as: Event.self)
                }
            }
    }
    
    func createEvent(title: String, description: String, date: Date, location: String, eventLink: String?, hashtags: String?, createdBy: String) async throws {
        let event = Event(
            title: title,
            description: description,
            date: date,
            location: location,
            eventLink: eventLink,
            hashtags: hashtags,
            createdBy: createdBy,
            createdAt: Date(),
            attendees: [],
            isActive: true
        )
        
        try await db.collection(eventsCollection).addDocument(from: event)
    }
    
    func fetchEvents() async throws {
        let snapshot = try await db.collection(eventsCollection)
            .order(by: "date", descending: false)
            .getDocuments()
        
        events = try snapshot.documents.compactMap { document in
            try document.data(as: Event.self)
        }
    }
    
    func toggleEventAttendance(eventId: String, userId: String) async throws {
        let eventRef = db.collection(eventsCollection).document(eventId)
        
        try await db.runTransaction { transaction, errorPointer in
            let eventDocument: DocumentSnapshot
            do {
                eventDocument = try transaction.getDocument(eventRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var event = try? eventDocument.data(as: Event.self) else {
                let error = NSError(domain: "EventRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode event data"])
                errorPointer?.pointee = error
                return nil
            }
            
            if event.attendees.contains(userId) {
                event.attendees.removeAll { $0 == userId }
            } else {
                event.attendees.append(userId)
            }
            
            do {
                try transaction.setData(from: event, forDocument: eventRef)
            } catch let setError as NSError {
                errorPointer?.pointee = setError
                return nil
            }
            
            return nil
        }
    }
    
    func deleteEvent(eventId: String) async throws {
        try await db.collection(eventsCollection).document(eventId).delete()
    }
} 
