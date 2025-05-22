import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var birthdayService: BirthdayService
    @EnvironmentObject private var userRepository: UserRepository
    @StateObject private var notificationService = NotificationService.shared
    @State private var showUserProfile = false
    @State private var showEventDetails = false
    @State private var showPostDetails = false
    
    let tabs = ["Home", "Feed", "Directory", "Events", "Profile"]
    
    // Add these properties
    @State private var scrollProxy: ScrollViewProxy? = nil
    @Namespace private var namespace
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { proxy in
                        HStack(spacing: 30) {
                            ForEach(0..<tabs.count, id: \.self) { index in
                                VStack {
                                    Text(tabs[index])
                                        .foregroundColor(selectedTab == index ? .primary : .secondary)
                                        .fontWeight(selectedTab == index ? .bold : .regular)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 12)
                                    
                                    // Active tab indicator
                                    Rectangle()
                                        .frame(height: 2)
                                        .foregroundColor(selectedTab == index ? Color(red: 0.831, green: 0.686, blue: 0.216) : .clear)
                                }
                                .id(index) // Add id for scrolling
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        selectedTab = index
                                        // Dismiss keyboard when changing tabs
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                .background(Color(.secondarySystemBackground))
                .shadow(color: Color(.systemGray4), radius: 4, y: 2)
                
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
                    
                    ProfileView()
                        .environmentObject(authManager)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: selectedTab) { newValue in
                    // Scroll to keep selected tab in view
                    withAnimation {
                        scrollProxy?.scrollTo(newValue, anchor: .center)
                        // Dismiss keyboard when changing tabs
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay {
                if birthdayService.shouldShowBirthdayDialog {
                    BirthdayDialogView(userRepository: userRepository)
                }
            }
            .task {
                // Wait a short delay to ensure the view is fully loaded
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                birthdayService.checkAndShowBirthdayDialog()
            }
            .onChange(of: notificationService.selectedUserId) { userId in
                if let userId = userId {
                    selectedTab = 2 // Switch to Directory tab
                    showUserProfile = true
                }
            }
            .onChange(of: notificationService.selectedEventId) { eventId in
                if let eventId = eventId {
                    selectedTab = 3 // Switch to Events tab
                    showEventDetails = true
                }
            }
            .onChange(of: notificationService.selectedPostId) { postId in
                if let postId = postId {
                    selectedTab = 1 // Switch to Feed tab
                    showPostDetails = true
                }
            }
            .sheet(isPresented: $showUserProfile) {
                if let userId = notificationService.selectedUserId {
                    ProfileView(userId: userId)
                        .environmentObject(authManager)
                        .onDisappear {
                            notificationService.selectedUserId = nil
                        }
                }
            }
            .sheet(isPresented: $showEventDetails) {
                if let eventId = notificationService.selectedEventId {
                    EventDetailView(userRepository: userRepository, eventRepository: EventRepository(), eventId: eventId)
                        .onDisappear {
                            notificationService.selectedEventId = nil
                        }
                }
            }
            .sheet(isPresented: $showPostDetails) {
                if let postId = notificationService.selectedPostId {
                    PostDetailSheet(postId: postId)
                        .environmentObject(authManager)
                        .onDisappear {
                            notificationService.selectedPostId = nil
                        }
                }
            }
        }
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
