import SwiftUI

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
    @StateObject private var postRepository = PostRepository()
    
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
        .onAppear {
            Task {
                do {
                    try await eventRepository.fetchEvents()
                    try await postRepository.fetchPosts()
                } catch {
                    print("Error fetching data: \(error.localizedDescription)")
                }
            }
        }
    }
} 