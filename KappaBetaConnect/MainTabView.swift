import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var authManager: AuthManager
    
    let tabs = ["Home", "Feed", "Directory", "Events", "Messages", "Profile"]
    
    // Add these properties
    @State private var scrollProxy: ScrollViewProxy? = nil
    @Namespace private var namespace
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Tab Bar
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 30) {
                        ForEach(0..<tabs.count, id: \.self) { index in
                            VStack {
                                Text(tabs[index])
                                    .foregroundColor(selectedTab == index ? .black : .gray)
                                    .fontWeight(selectedTab == index ? .bold : .regular)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                
                                // Active tab indicator
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(selectedTab == index ? .black : .clear)
                            }
                            .id(index) // Add id for scrolling
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    selectedTab = index
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .onAppear {
                        scrollProxy = proxy
                    }
                }
            }
            .background(Color.white)
            .shadow(color: .gray.opacity(0.2), radius: 4, y: 2)
            
            // Tab Content
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                FeedView()
                    .tag(1)
                
                DirectoryView()
                    .tag(2)
                
                EventsView()
                    .tag(3)
                
                MessagesView()
                    .tag(4)
                
                ProfileView()
                    .environmentObject(authManager)
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: selectedTab) { newValue in
                // Scroll to keep selected tab in view
                withAnimation {
                    scrollProxy?.scrollTo(newValue, anchor: .center)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// Placeholder Views
struct HomeView: View {
    // Sample data for new members - replace with actual data later
    let newMembers = [
        (name: "Nathan Cooke", city: "Jackson, MS"),
        (name: "Alfred Carter", city: "Atlanta, GA"),
        (name: "Victor Simon", city: "Chicago, IL"),
        (name: "Samuel Trotter", city: "Dallas, TX"),
        (name: "Austin Wheeler", city: "Miami, FL")
    ]
    
    @StateObject private var eventRepository = EventRepository()
    @StateObject private var userRepository = UserRepository()
    
    var upcomingEvents: [Event] {
        let now = Date()
        return eventRepository.events
            .filter { $0.date > now }
            .sorted { $0.date < $1.date }
            .prefix(2)
            .map { $0 }
    }
    
    // Add recommended connections data
    let recommendedConnections = [
        (name: "Fred West", title: "Job Title"),
        (name: "Edward Evans", title: "Company")
    ]
    
    // Add recent activity data
    let recentActivities = [
        (name: "Chris Ferrell", action: "added a photo", time: "2h ago"),
        (name: "Kieran J Williams", action: "commented on a post", time: "5h ago"),
        (name: "John Tatum", action: "joined the group", time: "1d ago")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back,")
                            .font(.title)
                            .fontWeight(.semibold)
                        if let firstName = userRepository.currentUser?.firstName {
                            Text("\(firstName)!")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    Image("kblogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .padding(.trailing, 0)
                }
                .padding(.top, 20)
                
                Text("New Members")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.leading, 20)
                    .padding(.top, 30)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(newMembers, id: \.name) { member in
                            VStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 30))
                                    )
                                
                                Text(member.name)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                
                                Text(member.city)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 80)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                Text("Upcoming Events")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.leading, 20)
                    .padding(.top, 40)
                
                if upcomingEvents.isEmpty {
                    Text("No upcoming events")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)
                } else {
                    VStack(spacing: 20) {
                        ForEach(upcomingEvents) { event in
                            NavigationLink(destination: EventDetailView(userRepository: UserRepository(), eventRepository: eventRepository, eventId: event.id ?? "")) {
                                HStack {
                                    // Date column
                                    let calendar = Calendar.current
                                    let month = calendar.shortMonthSymbols[calendar.component(.month, from: event.date) - 1].uppercased()
                                    let day = String(calendar.component(.day, from: event.date))
                                    
                                    VStack(alignment: .center) {
                                        Text(month)
                                            .font(.system(size: 14, weight: .medium))
                                        Text(day)
                                            .font(.system(size: 24, weight: .bold))
                                    }
                                    .frame(width: 50)
                                    
                                    // Event details
                                    VStack(alignment: .leading) {
                                        Text(event.title)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text(event.location)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.leading, 10)
                                    
                                    Spacer()
                                    
                                    // Chevron indicator
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 10)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                Text("Recommended Connections")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.leading, 20)
                    .padding(.top, 40)
                
                VStack(spacing: 15) {
                    ForEach(recommendedConnections, id: \.name) { connection in
                        HStack {
                            // Profile picture and details
                            HStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 24))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(connection.name)
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(connection.title)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding(.leading, 8)
                            }
                            
                            Spacer()
                            
                            // Connect button
                            Button(action: {
                                // Handle connect action
                            }) {
                                Text("Connect")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.black, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.leading, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 15)
                
                VStack(spacing: 15) {
                    ForEach(recentActivities, id: \.name) { activity in
                        HStack {
                            Text(activity.name)
                                .fontWeight(.semibold)
                            + Text(" \(activity.action)")
                            
                            Spacer()
                            
                            Text(activity.time)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            Task {
                do {
                    try await eventRepository.fetchEvents()
                } catch {
                    print("Error fetching events: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct DirectoryView: View {
    @StateObject private var userRepository = UserRepository()
    @State private var searchText = ""
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by name...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: searchText) { _ in
                            // Cancel any existing search task
                            searchTask?.cancel()
                            
                            // Create a new search task with debounce
                            searchTask = Task {
                                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                                if !Task.isCancelled {
                                    await searchUsers()
                                }
                            }
                        }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if users.isEmpty {
                    VStack {
                        Image(systemName: "person.3")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No members found")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(users) { user in
                                UserCard(user: user)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Directory")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                await searchUsers()
            }
        }
    }
    
    private func searchUsers() async {
        isLoading = true
        do {
            users = try await userRepository.searchUsers(byName: searchText)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct UserCard: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.headline)
                Spacer()
                if let lineNumber = user.lineNumber {
                    Text("Line \(lineNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let major = user.major {
                Text(major)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let company = user.company {
                Text(company)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
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
                            .textFieldStyle(RoundedBorderTextFieldStyle())
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
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Event Link
                    VStack(alignment: .leading) {
                        Text("Event Link")
                            .foregroundColor(.gray)
                        TextField("Enter event link", text: $eventLink)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
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
                            .textFieldStyle(RoundedBorderTextFieldStyle())
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
                        LazyVStack(spacing: 16) {
                            ForEach(filteredEvents) { event in
                                NavigationLink(destination: EventDetailView(userRepository: userRepository, eventRepository: eventRepository, eventId: event.id ?? "")) {
                                    EventListItem(event: event)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
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
            .onAppear {
                print("EventsView appeared")
                print("Current user: \(userRepository.currentUser?.id ?? "nil")")
                Task {
                    do {
                        try await eventRepository.fetchEvents()
                    } catch {
                        showError = true
                        errorMessage = error.localizedDescription
                    }
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
                        .background(Color.black)
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
        .padding(.vertical, 8)
    }
}

struct MessagesView: View {
    var body: some View {
        Text("Messages")
    }
}

struct ProfileView: View {
    let userName = "Titus Neyland"
    let jobTitle = "Software Engineer"
    let company = "Dillard's Inc."
    let location = "Little Rock, AR"
    let industry = "Technology"
    let yearsExperience = "5 years"
    let alumniStatus = "Alumni"
    let initiationYear = "2021"
    let lineName = "INDEUCED IN2ENT"
    let lineNumber = "2"
    let shipName = "12 INVADERS"
    let positions = ["Assistant Secretary"]
    let skills = ["iOS Development", "Swift", "SwiftUI", "UI/UX Design", "Project Management"]
    let interests = ["Technology", "Gaming", "Art", "Travel"]
    let bio = "Passionate software engineer with a focus on iOS development. Creating innovative solutions and mentoring junior developers. Always excited to learn new technologies and contribute to meaningful projects."
    let linkedin = "linkedin.com/in/titusneyland"
    
    // Add new properties for social media
    let instagram = "@username"
    let twitter = "@username"
    let snapchat = "@username"
    
    // Add environment object for AuthManager
    @EnvironmentObject private var authManager: AuthManager
    // State to control showing alert
    @State private var showLogoutAlert = false
    // State to control navigation back to login
    @State private var navigateToLogin = false
    
    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 25) {
                    // Profile Header
                    HStack(spacing: 15) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 110, height: 110)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 40))
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("\(jobTitle), \(company)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(location)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Professional Info Section
                    HStack(spacing: 30) {
                        InfoColumn(title: "Industry", value: industry)
                        InfoColumn(title: "Experience", value: yearsExperience)
                        InfoColumn(title: "Status", value: alumniStatus)
                    }
                    .padding(.horizontal, 20)
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                    }
                    
                    // Brotherhood Details Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Brotherhood Details")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 15) {
                            // First Row: Initiation and Line Info
                            HStack(spacing: 20) {
                                VStack(alignment: .leading) {
                                    Text("Initiated")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Fall \(initiationYear)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Line #")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("#\(lineNumber)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Ship")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(shipName)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Second Row: Line Name and Positions
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading) {
                                        Text("Line Name")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(lineName)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading) {
                                        Text("Positions")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        HStack {
                                            ForEach(positions, id: \.self) { position in
                                                Text(position)
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                                if position != positions.last {
                                                    Text("•")
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                    }
                    
                    // Skills Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Skills & Expertise")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(skills, id: \.self) { skill in
                                    Text(skill)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(15)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Interests Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Interests & Hobbies")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(15)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Connect Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Connect")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // LinkedIn
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Link("LinkedIn Profile", destination: URL(string: linkedin)!)
                                    .foregroundColor(.blue)
                            }
                            
                            // Instagram
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Link("Instagram", destination: URL(string: "https://instagram.com/\(instagram.replacingOccurrences(of: "@", with: ""))")!)
                                    .foregroundColor(.blue)
                            }
                            
                            // Twitter/X
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Link("Twitter", destination: URL(string: "https://twitter.com/\(twitter.replacingOccurrences(of: "@", with: ""))")!)
                                    .foregroundColor(.blue)
                            }
                            
                            // Snapchat
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Link("Snapchat", destination: URL(string: "https://snapchat.com/add/\(snapchat.replacingOccurrences(of: "@", with: ""))")!)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    }
                    
                    // Logout Button
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        Text("Logout")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 30)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            
            // Hidden NavigationLink that will trigger when navigateToLogin is true
            NavigationLink(destination: LoginView().navigationBarBackButtonHidden(true), isActive: $navigateToLogin) {
                EmptyView()
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                do {
                    try authManager.signOut()
                    navigateToLogin = true
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

// Helper view for info columns
struct InfoColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// Helper view for creating flowing tag layouts
struct FlowLayout<Content: View>: View {
    let items: [String]
    let spacing: CGFloat = 8
    let content: (String) -> Content
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height + spacing
                        }
                        let result = width
                        if item == items.last {
                            width = 0
                        } else {
                            width -= dimension.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last {
                            height = 0
                        }
                        return result
                    }
            }
        }
    }
}

// Update FeedView
struct FeedView: View {
    @StateObject private var postRepository = PostRepository()
    @EnvironmentObject private var authManager: AuthManager
    @State private var showNewPostSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var newPostContent = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(postRepository.posts) { post in
                            PostCard(post: post, postRepository: postRepository)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Feed")
            .overlay(
                Button(action: {
                    showNewPostSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.black)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20),
                alignment: .bottomTrailing
            )
            .sheet(isPresented: $showNewPostSheet) {
                NavigationView {
                    VStack {
                        TextEditor(text: $newPostContent)
                            .frame(height: 150)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4))
                            )
                            .padding()
                        
                        Spacer()
                    }
                    .navigationTitle("New Post")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showNewPostSheet = false
                                newPostContent = ""
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Post") {
                                createPost()
                            }
                            .disabled(newPostContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                do {
                    try await postRepository.fetchPosts()
                } catch {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func createPost() {
        guard let currentUser = authManager.currentUser else {
            showError = true
            errorMessage = "You must be logged in to create a post"
            return
        }
        
        Task {
            do {
                try await postRepository.createPost(
                    content: newPostContent,
                    authorId: currentUser.id ?? "",
                    authorName: "\(currentUser.firstName) \(currentUser.lastName)"
                )
                showNewPostSheet = false
                newPostContent = ""
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}

// Update PostCard
struct PostCard: View {
    let post: Post
    let postRepository: PostRepository
    @EnvironmentObject private var authManager: AuthManager
    @State private var showCommentSheet = false
    @State private var newComment = ""
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var isLiked: Bool {
        guard let userId = authManager.currentUser?.id else { return false }
        return post.likes.contains(userId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.headline)
                    Text(post.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Menu {
                    if post.authorId == authManager.currentUser?.id {
                        Button(role: .destructive, action: {}) {
                            Label("Delete", systemImage: "trash")
                        }
                    } else {
                        Button(action: {}) {
                            Label("Report", systemImage: "flag")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            // Post content
            Text(post.content)
                .font(.body)
            
            // Interaction counts
            HStack(spacing: 20) {
                Text("\(post.likes.count) likes")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(post.comments.count) comments")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(post.shareCount) shares")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Interaction buttons
            HStack(spacing: 20) {
                Button(action: {
                    handleLike()
                }) {
                    HStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                        Text("Like")
                    }
                    .foregroundColor(isLiked ? .red : .gray)
                }
                
                Button(action: {
                    showCommentSheet = true
                }) {
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("Comment")
                    }
                    .foregroundColor(.gray)
                }
                
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .foregroundColor(.gray)
                }
            }
            
            // Recent comments (show last 2)
            if !post.comments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(post.comments.suffix(2)) { comment in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(comment.authorName)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(comment.content)
                                .font(.caption)
                            Text(comment.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if post.comments.count > 2 {
                        Button(action: {
                            showCommentSheet = true
                        }) {
                            Text("View all \(post.comments.count) comments")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showCommentSheet) {
            NavigationView {
                VStack {
                    // Existing comments
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(post.comments) { comment in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(comment.authorName)
                                            .font(.headline)
                                        Spacer()
                                        Text(comment.timestamp.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Text(comment.content)
                                        .font(.body)
                                }
                                .padding(.horizontal)
                                Divider()
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // New comment input
                    HStack {
                        TextField("Add a comment...", text: $newComment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            handleComment()
                        }) {
                            Text("Post")
                                .fontWeight(.medium)
                        }
                        .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                }
                .navigationTitle("Comments")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showCommentSheet = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [post.content])
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleLike() {
        guard let userId = authManager.currentUser?.id else {
            showError = true
            errorMessage = "You must be logged in to like posts"
            return
        }
        
        Task {
            do {
                try await postRepository.toggleLike(postId: post.id ?? "", userId: userId)
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func handleComment() {
        guard let currentUser = authManager.currentUser else {
            showError = true
            errorMessage = "You must be logged in to comment"
            return
        }
        
        Task {
            do {
                try await postRepository.addComment(
                    postId: post.id ?? "",
                    content: newComment,
                    authorId: currentUser.id ?? "",
                    authorName: "\(currentUser.firstName) \(currentUser.lastName)"
                )
                newComment = ""
                showCommentSheet = false
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}

// Add ShareSheet for sharing functionality
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    MainTabView()
} 
