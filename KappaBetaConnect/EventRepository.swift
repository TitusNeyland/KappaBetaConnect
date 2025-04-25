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
                
                let fetchedEvents = documents.compactMap { document in
                    try? document.data(as: Event.self)
                }
                
                // Dispatch to main actor using Task
                Task { @MainActor in
                    self?.events = fetchedEvents
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
        
        let fetchedEvents = try snapshot.documents.compactMap { document in
            try document.data(as: Event.self)
        }
        
        // Update on main actor
        await MainActor.run {
            self.events = fetchedEvents
        }
    }
    
    func toggleEventAttendance(eventId: String, userId: String) async throws {
        let eventRef = db.collection(eventsCollection).document(eventId)
        
        let _ = try await db.runTransaction { [self] transaction, errorPointer -> Any? in
            do {
                let eventDocument = try transaction.getDocument(eventRef)
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
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
                
                // Store the updated attendees for later use
                let updatedAttendees = event.attendees
                
                // Schedule the UI update after the transaction completes
                Task { @MainActor in
                    if let index = self.events.firstIndex(where: { $0.id == eventId }) {
                        self.events[index].attendees = updatedAttendees
                    }
                }
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
    
    func deleteEvent(eventId: String) async throws {
        try await db.collection(eventsCollection).document(eventId).delete()
        
        // Update on main actor
        await MainActor.run {
            if let index = self.events.firstIndex(where: { $0.id == eventId }) {
                self.events.remove(at: index)
            }
        }
    }
    
    func updateEvent(eventId: String, title: String, description: String, date: Date, location: String, eventLink: String?, hashtags: String?) async throws {
        let eventRef = db.collection(eventsCollection).document(eventId)
        
        // Get the existing event to preserve createdBy and createdAt
        let eventDoc = try await eventRef.getDocument()
        guard let existingEvent = try? eventDoc.data(as: Event.self) else {
            throw NSError(domain: "EventRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode event data"])
        }
        
        let updatedEvent = Event(
            id: eventId,
            title: title,
            description: description,
            date: date,
            location: location,
            eventLink: eventLink,
            hashtags: hashtags,
            createdBy: existingEvent.createdBy,
            createdAt: existingEvent.createdAt,
            attendees: existingEvent.attendees,
            isActive: existingEvent.isActive
        )
        
        try await eventRef.setData(from: updatedEvent)
        
        // Update on main actor
        await MainActor.run {
            if let index = self.events.firstIndex(where: { $0.id == eventId }) {
                self.events[index] = updatedEvent
            }
        }
    }
} 
