import SwiftUI

struct EventsView: View {
    @StateObject private var eventRepository = EventRepository()
    @StateObject private var userRepository = UserRepository()
    @State private var showAddEventSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchText = ""
    
    var filteredEvents: [Event] {
        if searchText.isEmpty {
            return eventRepository.events
        }
        return eventRepository.events.filter { event in
            event.title.localizedCaseInsensitiveContains(searchText) ||
            event.location.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
                
                if filteredEvents.isEmpty {
                    VStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No events scheduled")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredEvents) { event in
                                NavigationLink(destination: EventDetailView(userRepository: userRepository, eventRepository: eventRepository, eventId: event.id ?? "")) {
                                    EventListItem(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Events")
            .sheet(isPresented: $showAddEventSheet, onDismiss: {
                Task {
                    do {
                        try await eventRepository.fetchEvents()
                    } catch {
                        showError = true
                        errorMessage = error.localizedDescription
                    }
                }
            }) {
                AddEventView(eventRepository: eventRepository, userRepository: userRepository)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                do {
                    try await eventRepository.fetchEvents()
                } catch {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
            .overlay(
                Button(action: {
                    print("Add event button tapped")
                    print("Current user: \(userRepository.currentUser?.id ?? "nil")")
                    if let currentUser = userRepository.currentUser {
                        print("User is logged in: \(currentUser.firstName) \(currentUser.lastName)")
                        showAddEventSheet = true
                    } else {
                        print("No user logged in")
                        showError = true
                        errorMessage = "Please log in to create events"
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(red: 0.831, green: 0.686, blue: 0.216))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20),
                alignment: .bottomTrailing
            )
        }
    }
}

struct EventListItem: View {
    let event: Event
    
    private var dateComponents: (month: String, day: String, dayOfWeek: String, time: String) {
        let calendar = Calendar.current
        let date = event.date
        let month = calendar.shortMonthSymbols[calendar.component(.month, from: date) - 1].uppercased()
        let day = String(calendar.component(.day, from: date))
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: date)
        formatter.dateFormat = "h:mm a"
        let time = formatter.string(from: date)
        return (month, day, dayOfWeek, time)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Date Box
            VStack {
                Text(dateComponents.month)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(dateComponents.day)
                    .font(.title)
                    .fontWeight(.bold)
            }
            .frame(width: 60)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            // Event Details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                Text("\(dateComponents.dayOfWeek), \(dateComponents.month) \(dateComponents.day), \(dateComponents.time)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(event.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal, 8)
    }
}

struct EventDetailView: View {
    @ObservedObject var userRepository: UserRepository
    @ObservedObject var eventRepository: EventRepository
    let eventId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showMenu = false
    
    private var event: Event? {
        eventRepository.events.first { $0.id == eventId }
    }
    
    private var isEventCreator: Bool {
        guard let event = event, let currentUserId = userRepository.currentUser?.id else { return false }
        return event.createdBy == currentUserId
    }
    
    private var dateComponents: (dayOfWeek: String, month: String, day: String, year: String, time: String)? {
        guard let event = event else { return nil }
        let calendar = Calendar.current
        let date = event.date
        let month = calendar.monthSymbols[calendar.component(.month, from: date) - 1]
        let day = String(calendar.component(.day, from: date))
        let year = String(calendar.component(.year, from: date))
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: date)
        formatter.dateFormat = "h:mm a"
        let time = formatter.string(from: date)
        return (dayOfWeek, month, day, year, time)
    }
    
    private func handleURLTap(_ urlString: String) {
        // Add http:// if no scheme is specified
        let urlStringWithScheme = urlString.lowercased().hasPrefix("http") ? urlString : "https://" + urlString
        
        guard let url = URL(string: urlStringWithScheme) else {
            showError = true
            errorMessage = "Invalid URL format"
            return
        }
        
        openURL(url) { success in
            if !success {
                showError = true
                errorMessage = "Could not open the URL"
            }
        }
    }
    
    var body: some View {
        Group {
            if let event = event, let dateComponents = dateComponents {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title with menu for creator
                        HStack {
                            Text(event.title)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if isEventCreator {
                                Spacer()
                                Menu {
                                    Button(action: { showEditSheet = true }) {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(.gray)
                                        .padding(8)
                                }
                            }
                        }
                        
                        // Date and Time
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date & Time")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("\(dateComponents.dayOfWeek), \(dateComponents.month) \(dateComponents.day), \(dateComponents.year)")
                                .font(.body)
                            Text(dateComponents.time)
                                .font(.body)
                        }
                        
                        // Location
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text(event.location)
                                .font(.body)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text(event.description)
                                .font(.body)
                        }
                        
                        // Event Link
                        if let eventLink = event.eventLink, !eventLink.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Event Link")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Button(action: {
                                    handleURLTap(eventLink)
                                }) {
                                    Text(eventLink)
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .underline()
                                }
                            }
                        }
                        
                        // Hashtags
                        if let hashtags = event.hashtags, !hashtags.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hashtags")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text(hashtags)
                                    .font(.body)
                            }
                        }
                        
                        // Attendance
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Attendance")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("\(event.attendees.count) attending")
                                .font(.body)
                        }
                        
                        // RSVP Button
                        if let userId = userRepository.currentUser?.id {
                            Button(action: {
                                Task {
                                    do {
                                        try await eventRepository.toggleEventAttendance(
                                            eventId: event.id ?? "",
                                            userId: userId
                                        )
                                    } catch {
                                        showError = true
                                        errorMessage = error.localizedDescription
                                    }
                                }
                            }) {
                                Text(event.attendees.contains(userId) ? "Cancel RSVP" : "RSVP")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(event.attendees.contains(userId) ? Color.red : Color.black)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding()
                }
                .background(Color(.secondarySystemBackground))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            if let event = event {
                EditEventView(eventRepository: eventRepository, event: event)
            }
        }
        .alert("Delete Event", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        if let eventId = event?.id {
                            try await eventRepository.deleteEvent(eventId: eventId)
                            dismiss()
                        }
                    } catch {
                        showError = true
                        errorMessage = error.localizedDescription
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var eventRepository: EventRepository
    let event: Event
    
    @State private var eventName: String
    @State private var eventDate: Date
    @State private var location: String
    @State private var eventLink: String
    @State private var description: String
    @State private var hashtags: String
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(eventRepository: EventRepository, event: Event) {
        self.eventRepository = eventRepository
        self.event = event
        _eventName = State(initialValue: event.title)
        _eventDate = State(initialValue: event.date)
        _location = State(initialValue: event.location)
        _eventLink = State(initialValue: event.eventLink ?? "")
        _description = State(initialValue: event.description)
        _hashtags = State(initialValue: event.hashtags ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Event Name
                    VStack(alignment: .leading) {
                        Text("Event Name")
                            .foregroundColor(.gray)
                        TextField("Enter event name", text: $eventName)
                            .customTextField()
                    }
                    
                    // Date and Time
                    VStack(alignment: .leading) {
                        Text("Date and Time")
                            .foregroundColor(.gray)
                        DatePicker("", selection: $eventDate)
                            .datePickerStyle(.graphical)
                    }
                    
                    // Location
                    VStack(alignment: .leading) {
                        Text("Location")
                            .foregroundColor(.gray)
                        TextField("Enter location", text: $location)
                            .customTextField()
                    }
                    
                    // Event Link
                    VStack(alignment: .leading) {
                        Text("Event Link")
                            .foregroundColor(.gray)
                        TextField("Enter event link", text: $eventLink)
                            .customTextField()
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                    
                    // Description
                    VStack(alignment: .leading) {
                        Text("Description")
                            .foregroundColor(.gray)
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    
                    // Hashtags
                    VStack(alignment: .leading) {
                        Text("Hashtags")
                            .foregroundColor(.gray)
                        TextField("Enter hashtags (separated by spaces)", text: $hashtags)
                            .customTextField()
                    }
                    
                    // Update Event Button
                    Button(action: {
                        Task {
                            await updateEvent()
                        }
                    }) {
                        Text("Update Event")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    .disabled(eventName.isEmpty || location.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func updateEvent() async {
        do {
            try await eventRepository.updateEvent(
                eventId: event.id ?? "",
                title: eventName,
                description: description,
                date: eventDate,
                location: location,
                eventLink: eventLink.isEmpty ? nil : eventLink,
                hashtags: hashtags.isEmpty ? nil : hashtags
            )
            dismiss()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
} 