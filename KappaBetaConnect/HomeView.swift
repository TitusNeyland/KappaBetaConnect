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
                    
                    Image("kblogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .padding(.trailing, 0)
                }
                .padding(.top, 20)
                
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
                                    
                                    if let alias = member.alias {
                                        Text(alias)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(width: 80)
                                .onAppear {
                                    print("Displaying member: \(member.name) (Number: \(member.number))")
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
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
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(10)
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
        .onAppear {
            Task {
                do {
                    try await eventRepository.fetchEvents()
                    try await postRepository.fetchPosts()
                    
                    if let recentLine = try await lineRepository.fetchMostRecentLine() {
                        print("Found most recent line: \(recentLine.line_name) (\(recentLine.semester) \(recentLine.year))")
                        await MainActor.run {
                            self.newestMembers = recentLine.members.sorted(by: { $0.number < $1.number })
                            self.showNoLineMessage = false
                        }
                    } else {
                        print("No recent line found in database")
                        await MainActor.run {
                            self.showNoLineMessage = true
                        }
                    }
                } catch {
                    print("Error fetching data: \(error.localizedDescription)")
                    await MainActor.run {
                        self.showNoLineMessage = true
                    }
                }
            }
        }
        .task {
            await fetchRecommendedUsers()
        }
    }
    
    private func fetchRecommendedUsers() async {
        guard let currentUser = authManager.currentUser else { return }
        
        do {
            let allUsers = try await userRepository.searchUsers(byName: "")
            let recommendations = allUsers
                .filter { $0.id != currentUser.id } // Exclude current user
                .map { user -> (User, Double) in
                    let score = calculateSimilarityScore(currentUser: currentUser, otherUser: user)
                    return (user, score)
                }
                .sorted { $0.1 > $1.1 } // Sort by similarity score
                .prefix(5) // Get top 5 recommendations
                .map { $0.0 } // Get just the users
            
            await MainActor.run {
                self.recommendedUsers = Array(recommendations)
            }
        } catch {
            print("Error fetching recommended users: \(error)")
        }
    }
    
    private func calculateSimilarityScore(currentUser: User, otherUser: User) -> Double {
        var score = 0.0
        
        // Same city and state (highest weight)
        if currentUser.city == otherUser.city && currentUser.state == otherUser.state {
            score += 5.0
        }
        
        // Same career field
        if currentUser.careerField == otherUser.careerField {
            score += 4.0
        }
        
        // Same company
        if currentUser.company == otherUser.company {
            score += 4.0
        }
        
        // Same major
        if currentUser.major == otherUser.major {
            score += 3.0
        }
        
        // Same line number
        if currentUser.lineNumber == otherUser.lineNumber {
            score += 3.0
        }
        
        // Same initiation semester/year
        if currentUser.semester == otherUser.semester && currentUser.year == otherUser.year {
            score += 2.0
        }
        
        // Shared interests
        if let currentInterests = currentUser.interests,
           let otherInterests = otherUser.interests {
            let commonInterests = Set(currentInterests).intersection(Set(otherInterests))
            score += Double(commonInterests.count)
        }
        
        return score
    }
    
    private func getMainCommonality(currentUser: User?, otherUser: User) -> String? {
        guard let currentUser = currentUser else { return nil }
        
        // Check commonalities in priority order
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
