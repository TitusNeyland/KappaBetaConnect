import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    let tabs = ["Home", "Directory", "Events", "Messages", "Profile"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Tab Bar
            ScrollView(.horizontal, showsIndicators: false) {
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
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                selectedTab = index
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
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
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationBarHidden(true)
    }
}

// Placeholder Views
struct HomeView: View {
    // Sample data for new members - replace with actual data later
    let newMembers = [
        (name: "John Smith", city: "Houston, TX"),
        (name: "Michael Johnson", city: "Atlanta, GA"),
        (name: "David Williams", city: "Chicago, IL"),
        (name: "James Brown", city: "Dallas, TX"),
        (name: "Robert Davis", city: "Miami, FL")
    ]
    
    // Updated event data structure to split month and day
    let upcomingEvents = [
        (month: "APR", day: "25", name: "Event Name", location: "Location"),
        (month: "MAY", day: "3", name: "Event Name", location: "Location")
    ]
    
    // Add recommended connections data
    let recommendedConnections = [
        (name: "Michael Brown", title: "Job Title"),
        (name: "Emma Davis", title: "Company")
    ]
    
    // Add recent activity data
    let recentActivities = [
        (name: "Chris Wilson", action: "added a photo", time: "2h ago"),
        (name: "Rachel Moore", action: "commented on a post", time: "5h ago"),
        (name: "Daniel Lee", action: "joined the group", time: "1d ago")
    ]
    
    var body: some View {
        ScrollView { // Add ScrollView to handle all content
            VStack(alignment: .leading) {
                HStack {
                    Text("Welcome back!")
                        .font(.title)
                        .fontWeight(.bold)
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
    @State private var searchText = ""
    
    // Sample directory data
    let members = [
        (name: "John Doe", title: "Software Engineer"),
        (name: "Jane Smith", title: "Marketing Manager"),
        (name: "Bob Johnson", title: "Sales Associate"),
        (name: "Alice Williams", title: "Product Designer"),
        (name: "Michael Brown", title: "Account Executive"),
        (name: "Project Manager", title: "Creative Agency"),
        (name: "David Wilson", title: "Data Analyst"),
        (name: "Emily Johnson", title: "Consultant"),
        (name: "Kevin Johnson", title: "HR Specialist")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with logo
            HStack {
                Text("Directory")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image("kblogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .padding(.trailing, -20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Search bar and filters
            HStack(spacing: 15) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search", text: $searchText)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Button(action: {
                    // Handle filters
                }) {
                    Text("Filters")
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
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // Members list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(members, id: \.name) { member in
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 24))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(member.name)
                                        .font(.system(size: 17, weight: .semibold))
                                    Text(member.title)
                                        .font(.system(size: 15))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            
                            Divider()
                                .padding(.leading, 82)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

struct EventsView: View {
    var body: some View {
        Text("Events")
    }
}

struct MessagesView: View {
    var body: some View {
        Text("Messages")
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile")
    }
}

#Preview {
    MainTabView()
} 
