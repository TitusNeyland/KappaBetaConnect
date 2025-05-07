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

struct EnlargedImageView: View {
    let image: Image
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut) {
                        isPresented = false
                    }
                }
            
            VStack {
                Spacer()
                
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
        }
        .transition(.opacity)
        .navigationBarHidden(true)
    }
}

struct ManageProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userRepository: UserRepository
    @State private var prefix = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var suffix = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var major = ""
    @State private var city = ""
    @State private var state = ""
    @State private var homeCity = ""
    @State private var homeState = ""
    @State private var careerField = ""
    @State private var company = ""
    @State private var yearsOfExperience = ""
    @State private var lineNumber = ""
    @State private var semester = ""
    @State private var year = ""
    @State private var status = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var dialogTitle = "Error"
    @State private var shouldSignOut = false
    @EnvironmentObject private var authManager: AuthManager
    @State private var birthday = Date()
    @State private var jobTitle = ""
    
    let prefixes = ["Mr.", "Mrs.", "Ms.", "Dr.", "Prof.", "Rev.", "Hon."]
    let suffixes = ["Jr.", "Sr.", "II", "III", "IV", "V", "Ph.D.", "M.D.", "Esq."]
    let careerFields = [
        "Business & Finance",
        "Technology & Engineering",
        "Healthcare & Medicine",
        "Law & Legal Services",
        "Education & Research",
        "Government & Public Service",
        "Arts & Entertainment",
        "Marketing & Communications",
        "Science & Research",
        "Real Estate & Construction",
        "Non-Profit & Social Services",
        "Other"
    ]
    let lineNumbers = Array(1...50).map { String($0) }
    let semesters = ["Fall", "Spring"]
    let years: [String] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(1911...currentYear).map { String($0) }.reversed()
    }()
    let statuses = ["Collegiate", "Alumni"]
    let states = ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", 
                 "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", 
                 "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", 
                 "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", 
                 "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Prefix")
                                .foregroundColor(.gray)
                            Spacer()
                            Picker("", selection: $prefix) {
                                Text("Prefix").tag("")
                                ForEach(prefixes, id: \.self) { prefix in
                                    Text(prefix).tag(prefix)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 100)
                        }
                        
                        TextField("First Name", text: $firstName)
                        
                        TextField("Last Name", text: $lastName)
                        
                        HStack {
                            Text("Suffix")
                                .foregroundColor(.gray)
                            Spacer()
                            Picker("", selection: $suffix) {
                                Text("Suffix").tag("")
                                ForEach(suffixes, id: \.self) { suffix in
                                    Text(suffix).tag(suffix)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 100)
                        }
                        
                        DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                            .datePickerStyle(.compact)
                        
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        TextField("Phone Number", text: $phoneNumber)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                }
                
                Section(header: Text("Education")) {
                    TextField("Major", text: $major)
                }
                
                Section(header: Text("Current Location")) {
                    TextField("City", text: $city)
                    HStack {
                        Text("State")
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("", selection: $state) {
                            Text("Select").tag("")
                            ForEach(states, id: \.self) { state in
                                Text(state).tag(state)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.black)
                    }
                }
                
                Section(header: Text("Hometown")) {
                    TextField("City", text: $homeCity)
                    HStack {
                        Text("State")
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("", selection: $homeState) {
                            Text("Select").tag("")
                            ForEach(states, id: \.self) { state in
                                Text(state).tag(state)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.black)
                    }
                }
                
                Section(header: Text("Career")) {
                    HStack {
                        Text("Career Field")
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("", selection: $careerField) {
                            Text("Select Career Field").tag("")
                            ForEach(careerFields, id: \.self) { field in
                                Text(field).tag(field)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.black)
                    }
                    
                    TextField("Job Title", text: $jobTitle)
                    
                    TextField("Company", text: $company)
                    
                    TextField("Years of Experience", text: $yearsOfExperience)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Initiation Details")) {
                    Picker("Line Number", selection: $lineNumber) {
                        Text("Select Line #").tag("")
                        ForEach(lineNumbers, id: \.self) { number in
                            Text(number).tag(number)
                        }
                    }
                    
                    Picker("Semester", selection: $semester) {
                        Text("Select Semester").tag("")
                        ForEach(semesters, id: \.self) { sem in
                            Text(sem).tag(sem)
                        }
                    }
                    
                    Picker("Year", selection: $year) {
                        Text("Select Year").tag("")
                        ForEach(years, id: \.self) { yr in
                            Text(yr).tag(yr)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        Text("Select Status").tag("")
                        ForEach(statuses, id: \.self) { stat in
                            Text(stat).tag(stat)
                        }
                    }
                }
            }
            .navigationTitle("Manage Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                loadCurrentUserData()
            }
            .alert(dialogTitle, isPresented: $showError) {
                Button("OK") {
                    if shouldSignOut {
                        do {
                            try authManager.signOut()
                        } catch {
                            print("Error signing out: \(error.localizedDescription)")
                        }
                    }
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadCurrentUserData() {
        if let user = userRepository.currentUser {
            prefix = user.prefix ?? ""
            firstName = user.firstName
            lastName = user.lastName
            suffix = user.suffix ?? ""
            email = user.email
            phoneNumber = user.phoneNumber
            major = user.major ?? ""
            city = user.city ?? ""
            state = user.state ?? ""
            homeCity = user.homeCity ?? ""
            homeState = user.homeState ?? ""
            careerField = user.careerField ?? ""
            company = user.company ?? ""
            jobTitle = user.jobTitle ?? ""
            yearsOfExperience = user.yearsOfExperience ?? ""
            lineNumber = user.lineNumber ?? ""
            semester = user.semester ?? ""
            year = user.year ?? ""
            status = user.status ?? ""
            birthday = user.birthday ?? Date()
        }
    }
    
    private func saveProfile() {
        isLoading = true
        
        // Validate required fields
        if firstName.isEmpty {
            showError = true
            errorMessage = "First name is required"
            isLoading = false
            return
        }
        
        if lastName.isEmpty {
            showError = true
            errorMessage = "Last name is required"
            isLoading = false
            return
        }
        
        if email.isEmpty {
            showError = true
            errorMessage = "Email is required"
            isLoading = false
            return
        }
        
        if !isValidEmail(email) {
            showError = true
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        Task {
            do {
                // Check if email has changed
                let currentEmail = userRepository.currentUser?.email ?? ""
                let emailChanged = email != currentEmail
                
                // Update user in Firestore
                var updatedUser = User(
                    id: userRepository.currentUser?.id ?? "",
                    prefix: nil,
                    firstName: "",
                    lastName: "",
                    suffix: nil,
                    email: "",
                    phoneNumber: "",
                    city: nil,
                    state: nil,
                    homeCity: nil,
                    homeState: nil,
                    careerField: nil,
                    major: nil,
                    jobTitle: nil,
                    company: nil,
                    bio: nil,
                    interests: nil,
                    lineNumber: nil,
                    semester: nil,
                    year: nil,
                    status: nil,
                    graduationYear: nil,
                    profileImageURL: userRepository.currentUser?.profileImageURL,
                    linkedInURL: nil,
                    instagramURL: nil,
                    twitterURL: nil,
                    snapchatURL: nil,
                    facebookURL: nil,
                    isActive: true
                )
                
                updatedUser.prefix = prefix
                updatedUser.firstName = firstName
                updatedUser.lastName = lastName
                updatedUser.suffix = suffix
                updatedUser.email = email
                updatedUser.phoneNumber = phoneNumber
                updatedUser.major = major
                updatedUser.city = city
                updatedUser.state = state
                updatedUser.homeCity = homeCity
                updatedUser.homeState = homeState
                updatedUser.careerField = careerField
                updatedUser.company = company
                updatedUser.jobTitle = jobTitle
                updatedUser.yearsOfExperience = yearsOfExperience
                updatedUser.lineNumber = lineNumber
                updatedUser.semester = semester
                updatedUser.year = year
                updatedUser.status = status
                updatedUser.updatedAt = Date()
                updatedUser.birthday = birthday
                
                // If email changed, update both Firestore and Firebase Auth
                if emailChanged {
                    do {
                        try await authManager.updateEmail(to: email)
                        
                        // Update the email in Firestore
                        updatedUser.email = email
                        try await userRepository.updateUser(updatedUser)
                        
                        // Show success message for email verification
                        dialogTitle = "Email Update"
                        errorMessage = "A verification email has been sent to your new email address. You will be signed out to complete the email change process. Please sign in again with your new email once you've verified it."
                        showError = true
                        shouldSignOut = true
                        isLoading = false
                        return
                    } catch {
                        dialogTitle = "Error"
                        showError = true
                        errorMessage = "Failed to send verification email: \(error.localizedDescription)"
                        isLoading = false
                        return
                    }
                }
                
                // Only update the user in Firestore if email hasn't changed or if it's already verified
                try await userRepository.updateUser(updatedUser)
                dismiss()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct ProfileView: View {
    @StateObject private var postRepository = PostRepository()
    @StateObject private var userRepository = UserRepository()
    @StateObject private var lineRepository = LineRepository()
    @StateObject private var contentModeration = ContentModerationService()
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutAlert = false
    @State private var navigateToLogin = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showLinkedInEditSheet = false
    @State private var newLinkedInURL = ""
    @State private var showBioEditSheet = false
    @State private var showInterestsEditSheet = false
    @State private var interestsDidSave = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var userPosts: [Post] = []
    @State private var displayedUser: User?
    @State private var showSocialMediaEditSheet = false
    @State private var selectedSocialMedia: SocialMediaType = .linkedIn
    @State private var newSocialMediaURL = ""
    @State private var socialMediaDidSave = false
    @State private var showEnlargedImage = false
    @State private var enlargedImage: Image?
    @State private var bioDidSave = false
    @State private var showManageProfile = false
    @State private var userLine: Line?
    @State private var userLineDetails: (lineName: String, shipName: String)?
    @State private var userAlias: String?
    @State private var dialogTitle = "Error"
    @State private var shouldSignOut = false
    @State private var showHelpAndFAQ = false
    @State private var isUserBlocked = false
    
    // Optional parameter to view a different user's profile
    var userId: String?
    
    private var displayedUserId: String {
        userId ?? authManager.currentUser?.id ?? ""
    }
    
    private var isCurrentUserProfile: Bool {
        userId == nil || userId == authManager.currentUser?.id
    }
    
    private var recentPosts: [Post] {
        Array(userPosts.prefix(3))
    }
    
    // Sample data - replace with actual user data
    let lineName = "INDEUCED IN2ENT"
    let shipName = "12 INVADERS"
    let positions = ["Assistant Secretary"]
    let bio = "Passionate software engineer with a focus on iOS development. Creating innovative solutions and mentoring junior developers. Always excited to learn new technologies and contribute to meaningful projects."
    let instagram = "@username"
    let twitter = "@username"
    let snapchat = "@username"
    
    enum SocialMediaType: String, CaseIterable {
        case linkedIn = "LinkedIn"
        case instagram = "Instagram"
        case twitter = "X"
        case snapchat = "Snapchat"
        case facebook = "Facebook"
        
        var icon: String {
            switch self {
            case .linkedIn: return "person.2.fill"
            case .instagram: return "camera.fill"
            case .twitter: return "message.fill"
            case .snapchat: return "camera.viewfinder"
            case .facebook: return "person.circle.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Picture
                    VStack {
                        ZStack {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        enlargedImage = Image(uiImage: selectedImage)
                                        withAnimation(.easeIn) {
                                            showEnlargedImage = true
                                        }
                                    }
                            } else if let user = displayedUser ?? userRepository.currentUser,
                                      let profileImageURL = user.profileImageURL,
                                      let url = URL(string: profileImageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .onTapGesture {
                                            enlargedImage = image
                                            withAnimation(.easeIn) {
                                                showEnlargedImage = true
                                            }
                                        }
                                } placeholder: {
                                    ProgressView()
                                }
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
                            
                            if isCurrentUserProfile {
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.primary)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(Circle())
                                }
                                .offset(x: 40, y: 40)
                            }
                        }
                        .shadow(radius: 5)
                    }
                    .padding(.top, 20)
                    
                    // Profile Info
                    VStack(spacing: 20) {
                        // Name and Title
                        VStack(spacing: 4) {
                            if let user = displayedUser ?? userRepository.currentUser {
                                Text("\(user.firstName) \(user.lastName)\(user.suffix != nil ? ", \(user.suffix!)" : "")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if let jobTitle = user.jobTitle, let company = user.company {
                                    Text("\(jobTitle) at \(company)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                } else {
                                    Text("No job information available")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                if let city = user.city, let state = user.state {
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
                        .padding(.top, 10)
                        
                        // Quick Stats
                        HStack(spacing: 30) {
                            if let user = displayedUser ?? userRepository.currentUser {
                                if let careerField = user.careerField {
                                    InfoColumn(title: "Industry", value: careerField)
                                } else {
                                    InfoColumn(title: "Industry", value: "Not specified")
                                }
                                
                                if let yearsOfExperience = user.yearsOfExperience, !yearsOfExperience.isEmpty {
                                    InfoColumn(title: "Experience", value: "\(yearsOfExperience) years")
                                } else {
                                    InfoColumn(title: "Experience", value: "Not specified")
                                }
                                
                                if let status = user.status {
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
                                if isCurrentUserProfile {
                                    Button(action: {
                                        showBioEditSheet = true
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(Color(.label))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if let user = displayedUser ?? userRepository.currentUser {
                                VStack(alignment: .leading, spacing: 12) {
                                    // Bio
                                    if let bio = user.bio {
                                        Text(bio)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    // Contact Information
                                    VStack(alignment: .leading, spacing: 8) {
                                        if let major = user.major {
                                            HStack(spacing: 8) {
                                                Image(systemName: "graduationcap.fill")
                                                    .foregroundColor(.gray)
                                                Text("Major: \(major)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        HStack(spacing: 8) {
                                            Image(systemName: "envelope.fill")
                                                .foregroundColor(.gray)
                                            Text("Email: \(user.email)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        HStack(spacing: 8) {
                                            Image(systemName: "phone.fill")
                                                .foregroundColor(.gray)
                                            Text("Phone: \(user.phoneNumber)")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        if let homeCity = user.homeCity, let homeState = user.homeState {
                                            HStack(spacing: 8) {
                                                Image(systemName: "house.fill")
                                                    .foregroundColor(.gray)
                                                Text("Hometown: \(homeCity), \(homeState)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        // Add birthday
                                        HStack(spacing: 8) {
                                            Image(systemName: "calendar")
                                                .foregroundColor(.gray)
                                            Text("Birthday: \(formatDate(user.birthday))")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.top, 16)
                                }
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
                            
                            if userPosts.isEmpty {
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
                        initiationDetailsView
                        
                        // Interests Section
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Interests & Hobbies")
                                    .font(.headline)
                                Spacer()
                                if isCurrentUserProfile {
                                    Button(action: {
                                        showInterestsEditSheet = true
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(Color(.label))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    if let user = displayedUser ?? userRepository.currentUser,
                                       let userInterests = user.interests,
                                       !userInterests.isEmpty {
                                        ForEach(userInterests, id: \.self) { interest in
                                            Text(interest)
                                                .font(.subheadline)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(15)
                                        }
                                    } else {
                                        Text(isCurrentUserProfile ? "Add your interests here" : "No interests listed")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
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
                            
                            if isCurrentUserProfile {
                                Button(action: {
                                    showSocialMediaEditSheet = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Color(.label))
                                        .font(.system(size: 24))
                                }
                                .padding(.top, 5)
                            }
                            
                            if let user = displayedUser ?? userRepository.currentUser {
                                HStack(spacing: 15) {
                                    ForEach(SocialMediaType.allCases, id: \.self) { type in
                                        if let url = getSocialMediaURL(for: type, user: user) {
                                            Link(destination: URL(string: url)!) {
                                                VStack(spacing: 2) {
                                                    Image(systemName: type.icon)
                                                        .font(.system(size: 20))
                                                        .foregroundColor(.black)
                                                    Text(type.rawValue)
                                                        .font(.system(size: 9))
                                                        .foregroundColor(.black)
                                                }
                                            }
                                        } else {
                                            VStack(spacing: 2) {
                                                Image(systemName: type.icon)
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.gray)
                                                Text(type.rawValue)
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 10)
                                .padding(.top, 10)
                            }
                            
                            // Unblock button under Connect With Me
                            if !isCurrentUserProfile && isUserBlocked {
                                Button(action: {
                                    unblockUser()
                                }) {
                                    Text("Unblock User")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red)
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        
                        // Manage Profile Button
                        if isCurrentUserProfile {
                            VStack(spacing: 10) {
                                Button(action: {
                                    showManageProfile = true
                                }) {
                                    Text("Manage Profile")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.black)
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                
                                Button(action: {
                                    showLogoutAlert = true
                                }) {
                                    Text("Logout")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(red: 0.831, green: 0.686, blue: 0.216))
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 30)
                            }
                        }
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            
            if isUploading {
                ProgressView("Uploading image...")
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            
            NavigationLink(destination: LoginView().navigationBarBackButtonHidden(true), isActive: $navigateToLogin) {
                EmptyView()
            }
            
            if showEnlargedImage, let image = enlargedImage {
                EnlargedImageView(image: image, isPresented: $showEnlargedImage)
            }
            
            // Add floating Help & FAQ button and Email button
            if isCurrentUserProfile {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showHelpAndFAQ = true
                        }) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                                .frame(width: 50, height: 50)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            } else if let user = displayedUser {
                // Show email and chat buttons only for other users' profiles
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 20) {  // Increased spacing from 10 to 20 points
                            // Chat/Text Message Button
                            Button(action: {
                                if let url = URL(string: "sms:\(user.phoneNumber)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Image(systemName: "message.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                                    .frame(width: 50, height: 50)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            
                            // Email Button
                            Button(action: {
                                if let url = URL(string: "mailto:\(user.email)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Image(systemName: "envelope.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                                    .frame(width: 50, height: 50)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 40) // Reduced from 80 to 40 to move buttons lower
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(destination: EmptyView()) {
                    EmptyView()
                }
                .opacity(0)
            }
        }
        .toolbarColorScheme(.light, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                    Text("Back")
                        .foregroundColor(.black)
                }
            }
        )
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
            await fetchUserData()
            await fetchUserPosts()
            await checkIfUserIsBlocked()
        }
        .onChange(of: displayedUserId) { _ in
            Task {
                await fetchUserData()
                await fetchUserPosts()
                await checkIfUserIsBlocked()
            }
        }
        .refreshable {
            await fetchUserData()
            await fetchUserPosts()
        }
        .sheet(isPresented: $showLinkedInEditSheet) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Enter your LinkedIn URL")
                        .font(.headline)
                        .padding(.top)
                    
                    TextField("https://linkedin.com/in/username", text: $newLinkedInURL)
                        .customTextField()
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
                                    if var user = displayedUser ?? userRepository.currentUser {
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
            BioEditView(userRepository: userRepository, currentBio: displayedUser?.bio, didSave: $bioDidSave)
        }
        .onChange(of: showBioEditSheet) { isPresented in
            if !isPresented && bioDidSave {
                // Sheet was dismissed and changes were saved
                Task {
                    await fetchUserData()
                    bioDidSave = false
                }
            }
        }
        .sheet(isPresented: $showInterestsEditSheet) {
            InterestsEditView(userRepository: userRepository, didSave: $interestsDidSave)
        }
        .onChange(of: showInterestsEditSheet) { isPresented in
            if !isPresented && interestsDidSave {
                // Sheet was dismissed and changes were saved
                Task {
                    await fetchUserData()
                    interestsDidSave = false
                }
            }
        }
        .sheet(isPresented: $showSocialMediaEditSheet) {
            SocialMediaEditView(userRepository: userRepository, didSave: $socialMediaDidSave)
        }
        .onChange(of: showSocialMediaEditSheet) { isPresented in
            if !isPresented && socialMediaDidSave {
                // Sheet was dismissed and changes were saved
                Task {
                    await fetchUserData()
                    socialMediaDidSave = false
                }
            }
        }
        .sheet(isPresented: $showManageProfile) {
            ManageProfileView(userRepository: userRepository)
        }
        .onChange(of: showManageProfile) { oldValue, isPresented in
            if !isPresented {
                // Sheet was dismissed, refresh user data
                Task {
                    await fetchUserData()
                }
            }
        }
        .sheet(isPresented: $showHelpAndFAQ) {
            HelpAndFAQView()
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) async {
        guard let userId = displayedUser?.id ?? userRepository.currentUser?.id else { return }
        
        isUploading = true
        do {
            let imageURL = try await ImageService.shared.uploadProfileImage(image, userId: userId)
            if var user = displayedUser ?? userRepository.currentUser {
                user.profileImageURL = imageURL.absoluteString
                try await userRepository.updateUser(user)
            }
        } catch {
            showError = true
            errorMessage = "Failed to upload profile image: \(error.localizedDescription)"
        }
        isUploading = false
    }
    
    private func fetchUserPosts() async {
        guard !displayedUserId.isEmpty else { return }
        
        do {
            print("Fetching posts for user: \(displayedUserId)")
            let posts = try await postRepository.fetchPostsByAuthor(authorId: displayedUserId)
            print("Found \(posts.count) posts")
            await MainActor.run {
                self.userPosts = posts
            }
        } catch {
            print("Error fetching posts: \(error)")
            await MainActor.run {
                showError = true
                errorMessage = "Failed to load posts: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchUserData() async {
        guard !displayedUserId.isEmpty else { return }
        
        do {
            print("Fetching user data for: \(displayedUserId)")
            let user = try await userRepository.getUser(withId: displayedUserId)
            await MainActor.run {
                self.displayedUser = user
            }
            
            // Fetch line information if available
            if let user = user,
               let semester = user.semester,
               let yearStr = user.year,
               let year = Int(yearStr),
               let lineNumberStr = user.lineNumber,
               let lineNumber = Int(lineNumberStr) {
                
                if let line = try await lineRepository.findLine(semester: semester, year: year) {
                    await MainActor.run {
                        self.userLine = line
                        self.userLineDetails = (lineName: line.line_name, shipName: line.line_name)
                        if let memberDetails = lineRepository.getLineMemberDetails(line: line, lineNumber: lineNumber) {
                            self.userAlias = memberDetails.alias
                        }
                    }
                }
            }
            
            print("Successfully fetched user data")
        } catch {
            print("Error fetching user data: \(error)")
            await MainActor.run {
                showError = true
                errorMessage = "Failed to load user data: \(error.localizedDescription)"
            }
        }
    }
    
    private func getSocialMediaURL(for type: SocialMediaType, user: User) -> String? {
        switch type {
        case .linkedIn:
            return user.linkedInURL
        case .instagram:
            return user.instagramURL
        case .twitter:
            return user.twitterURL
        case .snapchat:
            return user.snapchatURL
        case .facebook:
            return user.facebookURL
        }
    }
    
    private var initiationDetailsView: some View {
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
                        if let user = displayedUser ?? userRepository.currentUser {
                            let semester = user.semester?.trimmingCharacters(in: .whitespacesAndNewlines)
                            let year = user.year?.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if let sem = semester, !sem.isEmpty,
                               let yr = year, !yr.isEmpty {
                                // Convert semester to abbreviated form and year to 'YY format
                                let abbreviatedSemester = sem == "Fall" ? "FA" : "SPR"
                                let abbreviatedYear = "'\(yr.suffix(2))"
                                Text("\(abbreviatedSemester) \(abbreviatedYear)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                Text("Not specified")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
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
                        if let user = displayedUser ?? userRepository.currentUser,
                           let lineNum = user.lineNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
                           !lineNum.isEmpty {
                            Text(lineNum)
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
                        Text(userLineDetails?.shipName ?? "Not specified")
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
                        Text((userAlias ?? "Not specified").uppercased())
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func checkIfUserIsBlocked() async {
        guard let currentUserId = authManager.currentUser?.id,
              let displayedUserId = displayedUser?.id else { return }
        
        do {
            let blockedUsers = try await contentModeration.getBlockedUsers(userId: currentUserId)
            await MainActor.run {
                isUserBlocked = blockedUsers.contains(displayedUserId)
            }
        } catch {
            print("Error checking blocked status: \(error.localizedDescription)")
        }
    }
    
    private func unblockUser() {
        guard let currentUserId = authManager.currentUser?.id,
              let displayedUserId = displayedUser?.id else { return }
        
        Task {
            do {
                try await contentModeration.unblockUser(userId: currentUserId, blockedUserId: displayedUserId)
                await MainActor.run {
                    isUserBlocked = false
                }
                // Refresh the feed to show the unblocked user's posts
                try await postRepository.fetchPosts()
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
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

struct InterestsEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedInterests: Set<String> = []
    @State private var newInterest = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @ObservedObject var userRepository: UserRepository
    @Binding var didSave: Bool
    
    private let predefinedInterests = [
        "Technology", "Gaming", "Art", "Travel", "Music", "Sports",
        "Reading", "Cooking", "Photography", "Fitness", "Movies",
        "Hiking", "Dancing", "Writing", "Coding", "Design",
        "Entrepreneurship", "Volunteering", "Fashion", "Cars"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Custom Interest Input
                HStack {
                    TextField("Add custom interest", text: $newInterest)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addCustomInterest) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                    .disabled(newInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                
                // Predefined Interests
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(predefinedInterests, id: \.self) { interest in
                            InterestToggleButton(
                                interest: interest,
                                isSelected: selectedInterests.contains(interest),
                                action: { toggleInterest(interest) }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Interests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveInterests()
                    }
                    .foregroundColor(.primary)
                }
            }
            .onAppear {
                // Initialize selected interests with current interests
                if let userInterests = userRepository.currentUser?.interests {
                    selectedInterests = Set(userInterests)
                }
            }
        }
    }
    
    private func addCustomInterest() {
        let trimmedInterest = newInterest.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedInterest.isEmpty && !selectedInterests.contains(trimmedInterest) {
            selectedInterests.insert(trimmedInterest)
            newInterest = ""
        }
    }
    
    private func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
    
    private func saveInterests() {
        Task {
            do {
                if var user = userRepository.currentUser {
                    user.interests = Array(selectedInterests)
                    try await userRepository.updateUser(user)
                    didSave = true
                    dismiss()
                }
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct InterestToggleButton: View {
    let interest: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(interest)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .orange : .primary)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 1)
                )
        }
    }
}

struct SocialMediaEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var userRepository: UserRepository
    @State private var linkedInURL = ""
    @State private var instagramURL = ""
    @State private var twitterURL = ""
    @State private var snapchatURL = ""
    @State private var facebookURL = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @Binding var didSave: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Social Media Links")) {
                    VStack(alignment: .leading) {
                        Text("LinkedIn")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("https://linkedin.com/in/username", text: $linkedInURL)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Instagram")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("https://instagram.com/username", text: $instagramURL)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("X (Twitter)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("https://x.com/username", text: $twitterURL)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Snapchat")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("https://snapchat.com/add/username", text: $snapchatURL)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Facebook")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("https://facebook.com/username", text: $facebookURL)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                }
                
                Section(footer: Text("Leave fields empty to remove links")) {
                    EmptyView()
                }
            }
            .navigationTitle("Edit Social Media")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundColor(.primary)
                }
            }
            .onAppear {
                loadCurrentURLs()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadCurrentURLs() {
        if let user = userRepository.currentUser {
            linkedInURL = user.linkedInURL ?? ""
            instagramURL = user.instagramURL ?? ""
            twitterURL = user.twitterURL ?? ""
            snapchatURL = user.snapchatURL ?? ""
            facebookURL = user.facebookURL ?? ""
        }
    }
    
    private func validateAndFormatURL(_ url: String) -> String? {
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedURL.isEmpty {
            return nil
        }
        
        var formattedURL = trimmedURL
        if !formattedURL.lowercased().hasPrefix("http") {
            formattedURL = "https://" + formattedURL
        }
        
        guard URL(string: formattedURL) != nil else {
            return nil
        }
        
        return formattedURL
    }
    
    private func saveChanges() {
        Task {
            do {
                if var user = userRepository.currentUser {
                    user.linkedInURL = validateAndFormatURL(linkedInURL)
                    user.instagramURL = validateAndFormatURL(instagramURL)
                    user.twitterURL = validateAndFormatURL(twitterURL)
                    user.snapchatURL = validateAndFormatURL(snapchatURL)
                    user.facebookURL = validateAndFormatURL(facebookURL)
                    
                    try await userRepository.updateUser(user)
                    didSave = true
                    dismiss()
                }
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
} 