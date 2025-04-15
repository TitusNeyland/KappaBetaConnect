import SwiftUI
import FirebaseStorage
import PhotosUI

class ImageService {
    static let shared = ImageService()
    private let storage = Storage.storage(url: "gs://kappa-beta-connect.firebasestorage.app")
    
    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> URL {
        // Convert image to data
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw NSError(domain: "ImageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // Create storage reference
        let storageRef = storage.reference().child("profile_images/\(userId).jpg")
        
        // Upload the image
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        
        // Get the download URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL
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
    @State private var showBioEditSheet = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    
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
                            ZStack {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else if let currentUser = userRepository.currentUser,
                                          let profileImageURL = currentUser.profileImageURL,
                                          let url = URL(string: profileImageURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 50))
                                        )
                                }
                                
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.blue)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .offset(x: 40, y: 40)
                            }
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
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if let jobTitle = currentUser.jobTitle, let company = currentUser.company {
                                    Text("\(jobTitle) at \(company)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                } else {
                                    Text("No job information available")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                if let city = currentUser.city, let state = currentUser.state {
                                    Text("\(city), \(state)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                } else {
                                    Text("No location information available")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Text("Loading...")
                                    .font(.title2)
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
                            HStack {
                                Text("About")
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    showBioEditSheet = true
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if let currentUser = userRepository.currentUser {
                                Text(currentUser.bio ?? "No bio available")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                            } else {
                                Text("Loading...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        // Recent Posts Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Posts")
                                .font(.headline)
                                .padding(.horizontal, 20)
                            
                            if recentPosts.isEmpty {
                                Text("No recent posts")
                                    .font(.subheadline)
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
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            
                            VStack(spacing: 25) {
                                // First row: Initiated, Line #, Ship
                                HStack(spacing: 30) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Initiated")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        if let currentUser = userRepository.currentUser,
                                           let semester = currentUser.semester,
                                           let year = currentUser.year {
                                            // Convert semester to abbreviated form and year to 'YY format
                                            let abbreviatedSemester = semester == "Fall" ? "FA" : "SPR"
                                            let abbreviatedYear = "'\(year.suffix(2))"
                                            Text("\(abbreviatedSemester) \(abbreviatedYear)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        } else {
                                            Text("Not specified")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Line #")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        if let currentUser = userRepository.currentUser,
                                           let lineNumber = currentUser.lineNumber {
                                            Text(lineNumber)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        } else {
                                            Text("Not specified")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Ship")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(shipName)
                                            .font(.subheadline)
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
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(lineName)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Positions")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        HStack {
                                            ForEach(positions, id: \.self) { position in
                                                Text(position)
                                                    .font(.subheadline)
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
                                .font(.headline)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(skills, id: \.self) { skill in
                                        Text(skill)
                                            .font(.subheadline)
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
                                .font(.headline)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(interests, id: \.self) { interest in
                                        Text(interest)
                                            .font(.subheadline)
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
                        VStack(alignment: .center, spacing: 10) {
                            HStack(spacing: 10) {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray)
                                
                                VStack(spacing: 0) {
                                    Text("CONNECT")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    Text("WITH ME")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                }
                                
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 20)
                            
                            if let currentUser = userRepository.currentUser {
                                HStack(spacing: 20) {
                                    if let linkedInURL = currentUser.linkedInURL {
                                        Link(destination: URL(string: linkedInURL)!) {
                                            VStack {
                                                Image(systemName: "link")
                                                    .foregroundColor(.blue)
                                                Text("LinkedIn")
                                                    .font(.subheadline)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    
                                    Link(destination: URL(string: "https://instagram.com/\(instagram.replacingOccurrences(of: "@", with: ""))")!) {
                                        VStack {
                                            Image(systemName: "link")
                                                .foregroundColor(.blue)
                                            Text("Instagram")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    Link(destination: URL(string: "https://twitter.com/\(twitter.replacingOccurrences(of: "@", with: ""))")!) {
                                        VStack {
                                            Image(systemName: "link")
                                                .foregroundColor(.blue)
                                            Text("Twitter")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    Link(destination: URL(string: "https://snapchat.com/add/\(snapchat.replacingOccurrences(of: "@", with: ""))")!) {
                                        VStack {
                                            Image(systemName: "link")
                                                .foregroundColor(.blue)
                                            Text("Snapchat")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        
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
            
            if isUploading {
                ProgressView("Uploading image...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            
            NavigationLink(destination: LoginView().navigationBarBackButtonHidden(true), isActive: $navigateToLogin) {
                EmptyView()
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    await uploadProfileImage(image)
                }
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
        .sheet(isPresented: $showBioEditSheet) {
            BioEditView(userRepository: userRepository, currentBio: userRepository.currentUser?.bio)
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) async {
        guard let userId = userRepository.currentUser?.id else { return }
        
        isUploading = true
        do {
            let imageURL = try await ImageService.shared.uploadProfileImage(image, userId: userId)
            if var user = userRepository.currentUser {
                user.profileImageURL = imageURL.absoluteString
                try await userRepository.updateUser(user)
            }
        } catch {
            showError = true
            errorMessage = "Failed to upload profile image: \(error.localizedDescription)"
        }
        isUploading = false
    }
}

// Helper view for info columns
struct InfoColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
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