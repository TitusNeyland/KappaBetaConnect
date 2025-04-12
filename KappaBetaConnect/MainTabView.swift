import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var authManager: AuthManager
    
    let tabs = ["Home", "Directory", "Events", "Messages", "Profile"]
    
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
                
                DirectoryView()
                    .tag(1)
                
                EventsView()
                    .tag(2)
                
                MessagesView()
                    .tag(3)
                
                ProfileView()
                    .environmentObject(authManager)
                    .tag(4)
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
    
    // Updated event data structure to split month and day
    let upcomingEvents = [
        (month: "APR", day: "25", name: "Event Name", location: "Location"),
        (month: "MAY", day: "3", name: "Event Name", location: "Location")
    ]
    
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
        ScrollView { // Add ScrollView to handle all content
            VStack(alignment: .leading) {
                HStack {
                    Text("Welcome back!")
                        .font(.title)
                        .fontWeight(.semibold)
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
                
                VStack(spacing: 20) {
                    ForEach(upcomingEvents, id: \.name) { event in
                        HStack {
                            // Date column
                            VStack(alignment: .center) {
                                Text(event.month)
                                    .font(.system(size: 14, weight: .medium))
                                Text(event.day)
                                    .font(.system(size: 24, weight: .bold))
                            }
                            .frame(width: 50)
                            
                            // Event details
                            VStack(alignment: .leading) {
                                Text(event.name)
                                    .font(.system(size: 18, weight: .semibold))
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
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
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

struct EventsView: View {
    @State private var searchText = ""
    @State private var showAddEvent = false
    
    // Sample events data
    let events = [
        (month: "MAY", day: "12", title: "Networking Mixer", 
         date: "Sunday, May 12, 6:00 PM", location: "Austin, TX"),
        (month: "MAY", day: "25", title: "Alumni Panel Discussion", 
         date: "Saturday, May 25, 2:00 PM", location: "New York, NY"),
        (month: "JUN", day: "5", title: "Volunteer Opportunity", 
         date: "Wednesday, June 5, 9:00 AM", location: "Chicago, IL"),
        (month: "JUN", day: "21", title: "Summer Social", 
         date: "Friday, June 21, 5:30 PM", location: "Los Angeles, CA")
    ]
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Header with logo
                HStack {
                    Text("Events")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image("kblogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .padding(.trailing, -20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search", text: $searchText)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Events list
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(Array(events.enumerated()), id: \.element.title) { index, event in
                            HStack(alignment: .top, spacing: 15) {
                                // Date box
                                VStack {
                                    Text(event.month)
                                        .font(.system(size: 14, weight: .medium))
                                    Text(event.day)
                                        .font(.system(size: 24, weight: .bold))
                                }
                                .frame(width: 60)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                
                                // Event details
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.system(size: 20, weight: .semibold))
                                    Text(event.date)
                                        .font(.system(size: 16))
                                    Text(event.location)
                                        .font(.system(size: 16))
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            if index < events.count - 1 {
                                Divider()
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .background(Color(.systemBackground))
            
            // Floating Action Button
            Button(action: {
                showAddEvent = true
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
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventView()
        }
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

#Preview {
    MainTabView()
} 
