import SwiftUI

struct HomeView: View {
    @StateObject private var eventRepository = EventRepository()
    @StateObject private var userRepository = UserRepository()
    @StateObject private var postRepository = PostRepository()
    @StateObject private var lineRepository = LineRepository()
    @EnvironmentObject private var authManager: AuthManager
    @State private var recommendedUsers: [User] = []
    @State private var newestMembers: [LineMember] = []
    @State private var newestMembersCity: [String: String] = [:]
    @State private var showNoLineMessage: Bool = false
    @State private var isLoading: Bool = true
    
    var upcomingEvents: [Event] {
        let now = Date()
        return eventRepository.events
            .filter { $0.date > now }
            .sorted { $0.date < $1.date }
            .prefix(2)
            .map { $0 }
    }
    
    var recentPosts: [Post] {
        postRepository.posts
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(3)
            .map { $0 }
    }
    
    // Add recommended connections data
    let recommendedConnections = [
        (name: "Fred West", title: "Job Title"),
        (name: "Edward Evans", title: "Company")
    ]
    
    private var recentActivities: [(name: String, action: String, time: Date)] {
        var activities: [(name: String, action: String, time: Date)] = []
        
        // Add post creation activities
        activities.append(contentsOf: postRepository.posts.map { post in
            (name: post.authorName, action: "created a post", time: post.timestamp)
        })
        
        // Add comment activities
        for post in postRepository.posts {
            activities.append(contentsOf: post.comments.map { comment in
                (name: comment.authorName, action: "commented on a post", time: comment.timestamp)
            })
        }
        
        // Sort by timestamp (newest first) and take the first 3
        return activities
            .sorted(by: { $0.time > $1.time })
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back,")
                            .font(.title)
                            .fontWeight(.semibold)
                        if let firstName = userRepository.currentUser?.firstName {
                            Text("\(firstName)!")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Button(action: {
                            if let url = URL(string: "https://cash.app/$kappabeta") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 24))
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        Image("kblogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 20)
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.horizontal, 20)
                
                Text("Newest Members")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.leading, 20)
                    .padding(.top, 30)
                
                if showNoLineMessage {
                    Text("No new members to display")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(newestMembers, id: \.number) { member in
                                NewestMemberCard(
                                    member: member,
                                    userRepository: userRepository,
                                    lineRepository: lineRepository
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.horizontal, 20)
                
                Text("Recent Posts")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.leading, 20)
                    .padding(.top, 40)
                
                if recentPosts.isEmpty {
                    Text("No recent posts")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)
                } else {
                    VStack(spacing: 15) {
                        ForEach(recentPosts) { post in
                            NavigationLink(destination: FeedView()) {
                                PostCard(post: post, postRepository: postRepository)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.horizontal, 20)
                
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
                            NavigationLink(destination: EventDetailView(userRepository: userRepository, eventRepository: eventRepository, eventId: event.id ?? "")) {
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
                                        .foregroundColor(.primary)
                                        .padding(.trailing, 10)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.horizontal, 20)
                
                Text("Recommended Connections")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.leading, 20)
                    .padding(.top, 40)
                
                VStack(spacing: 15) {
                    ForEach(recommendedUsers) { user in
                        NavigationLink(destination: ProfileView(userId: user.id)) {
                            HStack {
                                // Profile picture and details
                                HStack {
                                    if let profileImageURL = user.profileImageURL,
                                       let url = URL(string: profileImageURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 24))
                                            )
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(user.firstName) \(user.lastName)")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        if let commonality = getMainCommonality(currentUser: authManager.currentUser, otherUser: user) {
                                            Text(commonality)
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.leading, 8)
                                }
                                .padding(.leading, -8)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.horizontal, 20)
                
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.leading, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 15)
                
                if recentActivities.isEmpty {
                    Text("No recent activity")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                } else {
                    VStack(spacing: 15) {
                        ForEach(recentActivities, id: \.time) { activity in
                            HStack {
                                Text(activity.name)
                                    .fontWeight(.semibold)
                                + Text(" \(activity.action)")
                                
                                Spacer()
                                
                                Text(activity.time.timeAgoDisplay())
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .background(Color(.secondarySystemBackground))
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch events
            try await eventRepository.fetchEvents()
            
            // Fetch posts
            try await postRepository.fetchPosts()
            
            // Fetch most recent line
            if let recentLine = try await lineRepository.fetchMostRecentLine() {
                await MainActor.run {
                    self.newestMembers = recentLine.members.sorted(by: { $0.number < $1.number })
                    self.showNoLineMessage = false
                }
            } else {
                await MainActor.run {
                    self.showNoLineMessage = true
                }
            }
            
            // Fetch recommended users after other data is loaded
            await fetchRecommendedUsers()
        } catch {
            print("Error fetching data: \(error.localizedDescription)")
            await MainActor.run {
                self.showNoLineMessage = true
            }
        }
    }
    
    private func fetchRecommendedUsers() async {
        guard let currentUser = authManager.currentUser else { return }
        
        do {
            let allUsers = try await userRepository.searchUsers(byName: "")
            let recommendations = allUsers
                .filter { $0.id != currentUser.id }
                .map { user -> (User, Double) in
                    let score = calculateSimilarityScore(currentUser: currentUser, otherUser: user)
                    // Add a small random factor (between 0 and 0.1) to the score
                    let randomFactor = Double.random(in: 0...0.1)
                    return (user, score + randomFactor)
                }
                .sorted { $0.1 > $1.1 }
                .prefix(10) // Get more candidates than we need
                .shuffled() // Shuffle the top candidates
                .prefix(5) // Take the first 5 after shuffling
                .map { $0.0 }
            
            await MainActor.run {
                self.recommendedUsers = Array(recommendations)
            }
        } catch {
            print("Error fetching recommended users: \(error)")
        }
    }
    
    private func calculateSimilarityScore(currentUser: User, otherUser: User) -> Double {
        var score = 0.0
        
        // Birthday match (highest priority)
        let calendar = Calendar.current
        let currentUserBirthday = calendar.dateComponents([.month, .day], from: currentUser.birthday)
        let otherUserBirthday = calendar.dateComponents([.month, .day], from: otherUser.birthday)
        if currentUserBirthday.month == otherUserBirthday.month && 
           currentUserBirthday.day == otherUserBirthday.day {
            score += 0.5 // Highest weight for birthday match
        }
        
        // Hometown match (strong connection)
        if currentUser.homeCity == otherUser.homeCity && currentUser.homeState == otherUser.homeState {
            score += 0.3
        }
        
        // Current location match
        if currentUser.city == otherUser.city && currentUser.state == otherUser.state {
            score += 0.2
        }
        
        // Same line number (strong connection)
        if currentUser.lineNumber == otherUser.lineNumber {
            score += 0.3
        }
        
        // Same company
        if currentUser.company == otherUser.company {
            score += 0.2
        }
        
        // Same career field
        if currentUser.careerField == otherUser.careerField {
            score += 0.15
        }
        
        // Shared interests
        if let currentInterests = currentUser.interests,
           let otherInterests = otherUser.interests {
            let sharedInterests = Set(currentInterests).intersection(Set(otherInterests))
            score += Double(sharedInterests.count) * 0.1
        }
        
        // Same graduation year (for alumni)
        if currentUser.graduationYear == otherUser.graduationYear {
            score += 0.1
        }
        
        // Same status (collegiate/alumni)
        if currentUser.status == otherUser.status {
            score += 0.05
        }
        
        // Same major (for current students)
        if currentUser.major == otherUser.major {
            score += 0.1
        }
        
        return score
    }
    
    private func getMainCommonality(currentUser: User?, otherUser: User) -> String? {
        guard let currentUser = currentUser else { return nil }
        
        // Check commonalities in priority order
        
        // Check birthday match first
        let calendar = Calendar.current
        let currentUserBirthday = calendar.dateComponents([.month, .day], from: currentUser.birthday)
        let otherUserBirthday = calendar.dateComponents([.month, .day], from: otherUser.birthday)
        if currentUserBirthday.month == otherUserBirthday.month && 
           currentUserBirthday.day == otherUserBirthday.day {
            return "Shares your birthday!"
        }
        
        if currentUser.company == otherUser.company {
            return "Works at \(otherUser.company ?? "")"
        }
        
        if currentUser.careerField == otherUser.careerField {
            return "Same industry: \(otherUser.careerField ?? "")"
        }
        
        if currentUser.city == otherUser.city && currentUser.state == otherUser.state {
            return "Located in \(otherUser.city ?? ""), \(otherUser.state ?? "")"
        }
        
        if currentUser.lineNumber == otherUser.lineNumber {
            return "You share the same line number"
        }
        
        if let currentInterests = currentUser.interests,
           let otherInterests = otherUser.interests,
           let commonInterest = Set(currentInterests).intersection(Set(otherInterests)).first {
            return "Shares interest in \(commonInterest)"
        }
        
        return nil
    }
}

struct GradientRingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.831, green: 0.686, blue: 0.216),  // Gold
                            Color(red: 0.831, green: 0.686, blue: 0.216).opacity(0.5),  // Semi-transparent gold
                            Color(red: 0.831, green: 0.686, blue: 0.216),  // Gold
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }
} 
