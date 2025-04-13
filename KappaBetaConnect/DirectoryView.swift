import SwiftUI

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