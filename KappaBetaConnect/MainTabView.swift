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

// Add this extension before the HomeView
extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.second, .minute, .hour, .day, .weekOfYear, .month, .year], from: self, to: now)
        
        if let years = components.year, years > 0 {
            return years == 1 ? "1yr ago" : "\(years)yrs ago"
        }
        if let months = components.month, months > 0 {
            return months == 1 ? "1mo ago" : "\(months)mo ago"
        }
        if let weeks = components.weekOfYear, weeks > 0 {
            return weeks == 1 ? "1w ago" : "\(weeks)w ago"
        }
        if let days = components.day, days > 0 {
            return days == 1 ? "1d ago" : "\(days)d ago"
        }
        if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1h ago" : "\(hours)h ago"
        }
        if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1m ago" : "\(minutes)m ago"
        }
        if let seconds = components.second, seconds > 0 {
            return seconds < 5 ? "now" : "\(seconds)s ago"
        }
        return "now"
    }
}

// Add this extension before the PostCard view
extension String {
    func detectURLs() -> [(url: URL, range: Range<String.Index>)] {
        var urls: [(URL, Range<String.Index>)] = []
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        
        matches?.forEach { match in
            if let url = match.url,
               let range = Range(match.range, in: self) {
                urls.append((url, range))
            }
        }
        return urls
    }
}

struct MessagesView: View {
    var body: some View {
        Text("Messages")
    }
}

#Preview {
    MainTabView()
} 
