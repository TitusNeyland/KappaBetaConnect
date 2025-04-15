import SwiftUI

struct DirectoryView: View {
    @StateObject private var userRepository = UserRepository()
    @State private var searchText = ""
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by name...", text: $searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
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
            .onChange(of: scenePhase) { newPhase in
                if newPhase != .active {
                    isSearchFocused = false
                }
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
        HStack(spacing: 12) {
            // Profile Image
            if let profileImageURL = user.profileImageURL,
               let url = URL(string: profileImageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 8) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.headline)
                
                if let city = user.city, let state = user.state {
                    Text("\(city), \(state)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
} 