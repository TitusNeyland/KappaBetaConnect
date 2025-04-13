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

struct ProfileView: View {
    @StateObject private var postRepository = PostRepository()
    @StateObject private var userRepository = UserRepository()
    @EnvironmentObject private var authManager: AuthManager
    @State private var showLogoutAlert = false
    @State private var navigateToLogin = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showLinkedInEditSheet = false
    @State private var newLinkedInURL = ""
    
    // Sample data - replace with actual user data
    let yearsExperience = "5 years"
    let lineName = "INDEUCED IN2ENT"
    let shipName = "12 INVADERS"
    let positions = ["Assistant Secretary"]
    let skills = ["iOS Development", "Swift", "SwiftUI", "UI/UX Design", "Project Management"]
    let interests = ["Technology", "Gaming", "Art", "Travel"]
    let bio = "Passionate software engineer with a focus on iOS development. Creating innovative solutions and mentoring junior developers. Always excited to learn new technologies and contribute to meaningful projects."
    let instagram = "@username"
    let twitter = "@username"
    let snapchat = "@username"
    
    private var recentPosts: [Post] {
        Array(postRepository.posts.prefix(3))
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header with Cover Photo
                    ZStack(alignment: .bottom) {
                        // Cover Photo
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                            )
                        
                        // Profile Picture
                        VStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 50))
                                )
                                .offset(y: 60)
                                .shadow(radius: 5)
                        }
                    }
                    
                    // Profile Info
                    VStack(spacing: 20) {
                        // Name and Title
                        VStack(spacing: 4) {
                            if let currentUser = userRepository.currentUser {
                                Text("\(currentUser.firstName) \(currentUser.lastName)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                if let jobTitle = currentUser.jobTitle, let company = currentUser.company {
                                    Text("\(jobTitle) at \(company)")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                } else {
                                    Text("No job information available")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                }
                                
                                if let city = currentUser.city, let state = currentUser.state {
                                    Text("\(city), \(state)")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                } else {
                                    Text("No location information available")
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Text("Loading...")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding(.top, 60)
                        
                        // Quick Stats
                        HStack(spacing: 30) {
                            if let currentUser = userRepository.currentUser {
                                if let careerField = currentUser.careerField {
                                    InfoColumn(title: "Industry", value: careerField)
                                } else {
                                    InfoColumn(title: "Industry", value: "Not specified")
                                }
                                
                                InfoColumn(title: "Experience", value: yearsExperience)
                                
                                if let status = currentUser.status {
                                    InfoColumn(title: "Status", value: status)
                                } else {
                                    InfoColumn(title: "Status", value: "Not specified")
                                }
                            } else {
                                InfoColumn(title: "Industry", value: "Loading...")
                                InfoColumn(title: "Experience", value: "Loading...")
                                InfoColumn(title: "Status", value: "Loading...")
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("About")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 20)
                            
                            Text(bio)
                                .font(.title3)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                        }
                        
                        // Recent Posts Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Posts")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 20)
                            
                            if recentPosts.isEmpty {
                                Text("No recent posts")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                VStack(spacing: 15) {
                                    ForEach(recentPosts) { post in
                                        PostCard(post: post, postRepository: postRepository)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Brotherhood Details Section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Brotherhood Details")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            
                            VStack(spacing: 25) {
                                // First row: Initiated, Line #, Ship
                                HStack(spacing: 30) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Initiated")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                        if let currentUser = userRepository.currentUser,
                                           let semester = currentUser.semester,
                                           let year = currentUser.year {
                                            // Convert semester to abbreviated form and year to 'YY format
                                            let abbreviatedSemester = semester == "Fall" ? "FA" : "SPR"
                                            let abbreviatedYear = "'\(year.suffix(2))"
                                            Text("\(abbreviatedSemester) \(abbreviatedYear)")
                                                .font(.title3)
                                                .foregroundColor(.gray)
                                        } else {
                                            Text("Not specified")
                                                .font(.title3)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Line #")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                        if let currentUser = userRepository.currentUser,
                                           let lineNumber = currentUser.lineNumber {
                                            Text(lineNumber)
                                                .font(.title3)
                                                .foregroundColor(.gray)
                                        } else {
                                            Text("Not specified")
                                                .font(.title3)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Ship")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                        Text(shipName)
                                            .font(.title3)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                Divider()
                                    .padding(.horizontal, 20)
                                
                                // Second row: Line Name and Positions
                                VStack(alignment: .leading, spacing: 25) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Line Name")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                        Text(lineName)
                                            .font(.title3)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Positions")
                                            .font(.title3)
                                            .fontWeight(.medium)
                                        HStack {
                                            ForEach(positions, id: \.self) { position in
                                                Text(position)
                                                    .font(.title3)
                                                    .foregroundColor(.gray)
                                                if position != positions.last {
                                                    Text("•")
                                                        .foregroundColor(.gray)
                                                        .padding(.horizontal, 4)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 20)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(15)
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 10)
                        
                        // Skills Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Skills & Expertise")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(skills, id: \.self) { skill in
                                        Text(skill)
                                            .font(.title3)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(15)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Interests Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Interests & Hobbies")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(interests, id: \.self) { interest in
                                        Text(interest)
                                            .font(.title3)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(15)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Connect Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Connect")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                if let currentUser = userRepository.currentUser {
                                    HStack {
                                        if let linkedInURL = currentUser.linkedInURL {
                                            Link(destination: URL(string: linkedInURL)!) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: "link")
                                                        .foregroundColor(.blue)
                                                    Text("LinkedIn Profile")
                                                        .font(.title3)
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        } else {
                                            Text("Add LinkedIn Profile")
                                                .font(.title3)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            if let linkedInURL = currentUser.linkedInURL {
                                                newLinkedInURL = linkedInURL
                                            } else {
                                                newLinkedInURL = "https://linkedin.com/in/"
                                            }
                                            showLinkedInEditSheet = true
                                        }) {
                                            Image(systemName: "pencil")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    Link(destination: URL(string: "https://instagram.com/\(instagram.replacingOccurrences(of: "@", with: ""))")!) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "link")
                                                .foregroundColor(.blue)
                                            Text("Instagram")
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                            Spacer()
                                        }
                                    }
                                    
                                    Link(destination: URL(string: "https://twitter.com/\(twitter.replacingOccurrences(of: "@", with: ""))")!) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "link")
                                                .foregroundColor(.blue)
                                            Text("Twitter")
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                            Spacer()
                                        }
                                    }
                                    
                                    Link(destination: URL(string: "https://snapchat.com/add/\(snapchat.replacingOccurrences(of: "@", with: ""))")!) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "link")
                                                .foregroundColor(.blue)
                                            Text("Snapchat")
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                        }
                        
                        // Logout Button
                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            Text("Logout")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 30)
                    }
                }
            }
            .background(Color(.systemBackground))
            
            NavigationLink(destination: LoginView().navigationBarBackButtonHidden(true), isActive: $navigateToLogin) {
                EmptyView()
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                do {
                    try authManager.signOut()
                    navigateToLogin = true
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .task {
            do {
                try await postRepository.fetchPosts()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
        .sheet(isPresented: $showLinkedInEditSheet) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Enter your LinkedIn URL")
                        .font(.headline)
                        .padding(.top)
                    
                    TextField("https://linkedin.com/in/username", text: $newLinkedInURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .padding(.horizontal)
                        .frame(height: 50)
                        .font(.title3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4))
                        )
                        .padding(.horizontal)
                    
                    Text("Example: https://linkedin.com/in/username")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .navigationTitle("Edit LinkedIn URL")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showLinkedInEditSheet = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            Task {
                                do {
                                    if var user = userRepository.currentUser {
                                        // Format the URL properly before saving
                                        var formattedURL = newLinkedInURL.trimmingCharacters(in: .whitespacesAndNewlines)
                                        
                                        // If URL is not empty, ensure it has proper formatting
                                        if !formattedURL.isEmpty {
                                            // Add https:// if no scheme is present
                                            if !formattedURL.lowercased().hasPrefix("http") {
                                                formattedURL = "https://" + formattedURL
                                            }
                                            
                                            // Validate the URL
                                            guard URL(string: formattedURL) != nil else {
                                                showError = true
                                                errorMessage = "Please enter a valid URL"
                                                return
                                            }
                                        }
                                        
                                        user.linkedInURL = formattedURL.isEmpty ? nil : formattedURL
                                        try await userRepository.updateUser(user)
                                        showLinkedInEditSheet = false
                                    }
                                } catch {
                                    showError = true
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// Helper view for info columns
struct InfoColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3)
                .foregroundColor(.gray)
            Text(value)
                .font(.title3)
                .fontWeight(.medium)
        }
    }
}

// Helper view for creating flowing tag layouts
struct FlowLayout<Content: View>: View {
    let items: [String]
    let spacing: CGFloat = 8
    let content: (String) -> Content
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height + spacing
                        }
                        let result = width
                        if item == items.last {
                            width = 0
                        } else {
                            width -= dimension.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last {
                            height = 0
                        }
                        return result
                    }
            }
        }
    }
}

// Create Post Sheet View
struct CreatePostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var postRepository: PostRepository
    @EnvironmentObject private var authManager: AuthManager
    @Binding var showError: Bool
    @Binding var errorMessage: String
    @State private var newPostContent = ""
    
    private let maxCharacterCount = 500
    
    private var detectedLinks: [URL] {
        newPostContent.detectURLs().map { $0.url }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // User info header
                if let currentUser = authManager.currentUser {
                    UserHeaderView(user: currentUser)
                }
                
                // Post content editor
                PostEditorView(content: $newPostContent)
                
                // Link previews
                if !detectedLinks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Links detected:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        ForEach(detectedLinks, id: \.absoluteString) { url in
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Text(url.absoluteString)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Character count and guidelines
                PostGuidelinesView(contentCount: newPostContent.count, maxCount: maxCharacterCount)
                
                Spacer()
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                        newPostContent = ""
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        createPost()
                    }
                    .disabled(isPostButtonDisabled)
                    .font(.headline)
                    .foregroundColor(isPostButtonDisabled ? .gray : .black)
                }
            }
        }
    }
    
    private var isPostButtonDisabled: Bool {
        newPostContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        newPostContent.count > maxCharacterCount
    }
    
    private func createPost() {
        guard let currentUser = authManager.currentUser else {
            showError = true
            errorMessage = "You must be logged in to create a post"
            return
        }
        
        let content = newPostContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty && content.count <= maxCharacterCount else { return }
        
        Task {
            do {
                try await postRepository.createPost(
                    content: content,
                    authorId: currentUser.id ?? "",
                    authorName: "\(currentUser.firstName) \(currentUser.lastName)"
                )
                dismiss()
                newPostContent = ""
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct UserHeaderView: View {
    let user: User
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.headline)
                Text("Posting to Feed")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct FocusedTextEditor: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.text = text.isEmpty ? placeholder : text
        textView.textColor = text.isEmpty ? .placeholderText : .label
        textView.becomeFirstResponder() // Automatically show keyboard
        
        // Prevent keyboard from being dismissed
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .none
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if text != uiView.text {
            uiView.text = text
        }
        if text.isEmpty && !uiView.isFirstResponder {
            uiView.text = placeholder
            uiView.textColor = .placeholderText
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: FocusedTextEditor
        
        init(_ parent: FocusedTextEditor) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if parent.text.isEmpty {
                textView.text = ""
                textView.textColor = .label
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if parent.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
        }
    }
}

struct PostEditorView: View {
    @Binding var content: String
    
    var body: some View {
        FocusedTextEditor(text: $content, placeholder: "What's on your mind?")
            .frame(minHeight: 150)
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal)
    }
}

struct PostGuidelinesView: View {
    let contentCount: Int
    let maxCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(contentCount)/\(maxCount)")
                    .font(.caption)
                    .foregroundColor(
                        contentCount > Int(Double(maxCount) * 0.8)
                        ? (contentCount > maxCount ? .red : .orange)
                        : .gray
                    )
                
                Spacer()
            }
            
            if contentCount > 0 {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                    Text("Your post will be visible to all fraternity members")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }
}

// Update PostCard
struct PostCard: View {
    let post: Post
    let postRepository: PostRepository
    @EnvironmentObject private var authManager: AuthManager
    @State private var showCommentSheet = false
    @State private var newComment = ""
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var isLiked: Bool {
        guard let userId = authManager.currentUser?.id else { return false }
        return post.likes.contains(userId)
    }
    
    private var recentComments: [Comment] {
        Array(post.comments.suffix(2).reversed())
    }
    
    private var allComments: [Comment] {
        Array(post.comments.reversed())
    }
    
    private func createAttributedContent() -> AttributedString {
        var attributed = AttributedString(post.content)
        let urls = post.content.detectURLs()
        
        for (url, range) in urls {
            if let attributedRange = Range(range, in: attributed) {
                attributed[attributedRange].foregroundColor = .blue
                attributed[attributedRange].underlineStyle = .single
                attributed[attributedRange].link = url
            }
        }
        
        return attributed
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.headline)
                    Text(post.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Menu {
                    if post.authorId == authManager.currentUser?.id {
                        Button(role: .destructive, action: {}) {
                            Label("Delete", systemImage: "trash")
                        }
                    } else {
                        Button(action: {}) {
                            Label("Report", systemImage: "flag")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            // Post content with clickable links
            Text(createAttributedContent())
                .font(.body)
                .environment(\.openURL, OpenURLAction { url in
                    print("Opening URL: \(url)")
                    return .systemAction
                })
            
            // Interaction counts
            HStack(spacing: 20) {
                Text("\(post.likes.count) likes")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(post.comments.count) comments")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(post.shareCount) shares")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Interaction buttons
            HStack(spacing: 20) {
                Button(action: {
                    handleLike()
                }) {
                    HStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                        Text("Like")
                    }
                    .foregroundColor(isLiked ? .red : .gray)
                }
                
                Button(action: {
                    showCommentSheet = true
                }) {
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("Comment")
                    }
                    .foregroundColor(.gray)
                }
                
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .foregroundColor(.gray)
                }
            }
            
            // Recent comments (show last 2)
            if !post.comments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recentComments) { comment in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(comment.authorName)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(comment.content)
                                .font(.caption)
                            Text(comment.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if post.comments.count > 2 {
                        Button(action: {
                            showCommentSheet = true
                        }) {
                            Text("View all \(post.comments.count) comments")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showCommentSheet) {
            NavigationView {
                VStack {
                    // Existing comments
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(allComments) { comment in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(comment.authorName)
                                            .font(.headline)
                                        Spacer()
                                        Text(comment.timestamp.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Text(comment.content)
                                        .font(.body)
                                }
                                .padding(.horizontal)
                                Divider()
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // New comment input
                    HStack {
                        TextField("Add a comment...", text: $newComment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            handleComment()
                        }) {
                            Text("Post")
                                .fontWeight(.medium)
                        }
                        .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                }
                .navigationTitle("Comments")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showCommentSheet = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [post.content])
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleLike() {
        guard let userId = authManager.currentUser?.id else {
            showError = true
            errorMessage = "You must be logged in to like posts"
            return
        }
        
        Task {
            do {
                try await postRepository.toggleLike(postId: post.id ?? "", userId: userId)
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func handleComment() {
        guard let currentUser = authManager.currentUser else {
            showError = true
            errorMessage = "You must be logged in to comment"
            return
        }
        
        let commentContent = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !commentContent.isEmpty else { return }
        
        Task {
            do {
                try await postRepository.addComment(
                    postId: post.id ?? "",
                    content: commentContent,
                    authorId: currentUser.id ?? "",
                    authorName: "\(currentUser.firstName) \(currentUser.lastName)"
                )
                
                newComment = ""
                showCommentSheet = false
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func handleShare() {
        Task {
            do {
                try await postRepository.incrementShareCount(postId: post.id ?? "")
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}

// Add ShareSheet for sharing functionality
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    MainTabView()
} 
