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
    var body: some View {
        VStack {
            HStack {
                Text("Welcome back!")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 20)
                
                Spacer()
                
                Image("kblogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .padding(.trailing, 20)
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

struct DirectoryView: View {
    var body: some View {
        Text("Directory")
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