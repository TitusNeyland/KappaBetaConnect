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
    @State private var showFilterSheet = false
    @State private var activeFilters: Filters = Filters()
    
    var filteredUsers: [User] {
        users.filter { user in
            var matches = true
            
            if let industry = activeFilters.industry, !industry.isEmpty {
                matches = matches && user.careerField?.lowercased() == industry.lowercased()
            }
            
            if let city = activeFilters.city, !city.isEmpty {
                matches = matches && user.city?.lowercased() == city.lowercased()
            }
            
            if let state = activeFilters.state, !state.isEmpty {
                matches = matches && user.state?.lowercased() == state.lowercased()
            }
            
            if let major = activeFilters.major, !major.isEmpty {
                matches = matches && user.major?.lowercased() == major.lowercased()
            }
            
            if let company = activeFilters.company, !company.isEmpty {
                matches = matches && user.company?.lowercased() == company.lowercased()
            }
            
            if let homeCity = activeFilters.homeCity, !homeCity.isEmpty {
                matches = matches && user.homeCity?.lowercased() == homeCity.lowercased()
            }
            
            if let homeState = activeFilters.homeState, !homeState.isEmpty {
                matches = matches && user.homeState?.lowercased() == homeState.lowercased()
            }
            
            return matches
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar and Filter Button
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search by name...", text: $searchText)
                            .textFieldStyle(.plain)
                            .focused($isSearchFocused)
                            .onChange(of: searchText) { _ in
                                searchTask?.cancel()
                                searchTask = Task {
                                    try? await Task.sleep(nanoseconds: 300_000_000)
                                    if !Task.isCancelled {
                                        await searchUsers()
                                    }
                                }
                            }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Filter Button
                    Button(action: {
                        showFilterSheet = true
                    }) {
                        Image(systemName: activeFilters.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(activeFilters.hasActiveFilters ? .blue : .gray)
                            .font(.system(size: 22))
                    }
                }
                .padding()
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredUsers.isEmpty {
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
                            ForEach(filteredUsers) { user in
                                UserCard(user: user)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Directory")
            .sheet(isPresented: $showFilterSheet) {
                FilterSheet(filters: $activeFilters)
            }
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
        NavigationLink(destination: ProfileView(userId: user.id)) {
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
                        .foregroundColor(.primary)
                    
                    if let city = user.city, let state = user.state {
                        Text("\(city), \(state)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
}

struct Filters {
    var industry: String?
    var city: String?
    var state: String?
    var major: String?
    var company: String?
    var homeCity: String?
    var homeState: String?
    
    var hasActiveFilters: Bool {
        return [industry, city, state, major, company, homeCity, homeState].contains { filter in
            filter != nil && !filter!.isEmpty
        }
    }
}

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: Filters
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Career")) {
                    TextField("Industry", text: Binding(
                        get: { filters.industry ?? "" },
                        set: { filters.industry = $0.isEmpty ? nil : $0 }
                    ))
                    .customTextField()
                    TextField("Company", text: Binding(
                        get: { filters.company ?? "" },
                        set: { filters.company = $0.isEmpty ? nil : $0 }
                    ))
                    .customTextField()
                }
                
                Section(header: Text("Education")) {
                    TextField("Major", text: Binding(
                        get: { filters.major ?? "" },
                        set: { filters.major = $0.isEmpty ? nil : $0 }
                    ))
                    .customTextField()
                }
                
                Section(header: Text("Current Location")) {
                    TextField("City", text: Binding(
                        get: { filters.city ?? "" },
                        set: { filters.city = $0.isEmpty ? nil : $0 }
                    ))
                    .customTextField()
                    TextField("State", text: Binding(
                        get: { filters.state ?? "" },
                        set: { filters.state = $0.isEmpty ? nil : $0 }
                    ))
                    .customTextField()
                }
                
                Section(header: Text("Hometown")) {
                    TextField("Hometown City", text: Binding(
                        get: { filters.homeCity ?? "" },
                        set: { filters.homeCity = $0.isEmpty ? nil : $0 }
                    ))
                    .customTextField()
                    TextField("Hometown State", text: Binding(
                        get: { filters.homeState ?? "" },
                        set: { filters.homeState = $0.isEmpty ? nil : $0 }
                    ))
                    .customTextField()
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        filters = Filters()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension TextFieldStyle where Self == PlainTextFieldStyle {
    func customTextField() -> some TextFieldStyle {
        self
    }
} 