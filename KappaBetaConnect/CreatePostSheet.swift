import SwiftUI
import PhotosUI

// Toast View (if needed elsewhere, keep in PostViews.swift)

struct CreatePostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var postRepository: PostRepository
    @EnvironmentObject private var authManager: AuthManager
    @Binding var showError: Bool
    @Binding var errorMessage: String
    @State private var newPostContent = ""
    @State private var pastedImage: UIImage? = nil
    @State private var showProfanityAlert = false
    @State private var lastCheckedContent = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false
    var didCreatePost: ((Bool) -> Void)?
    
    private let maxCharacterCount = 500
    
    private var detectedLinks: [URL] {
        newPostContent.detectURLs().map { $0.url }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 16) {
                    // User info header
                    if let currentUser = authManager.currentUser {
                        UserHeaderView(user: currentUser)
                    }
                    
                    // Post content editor with image preview inside the same background
                    VStack(spacing: 0) {
                        PasteablePostEditor(text: $newPostContent, pastedImage: $pastedImage, placeholder: "What's on your mind?")
                            .frame(minHeight: 100, maxHeight: 180)
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                        
                        if let image = pastedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 120)
                                    .cornerRadius(10)
                                    .padding([.horizontal, .bottom], 8)
                                Button(action: {
                                    pastedImage = nil
                                    selectedItem = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .offset(x: -4, y: 4)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Image picker button
                    HStack {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.831, green: 0.686, blue: 0.216))
                                .padding(8)
                                .background(Color(red: 0.831, green: 0.686, blue: 0.216).opacity(0.1))
                                .clipShape(Circle())
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    pastedImage = image
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
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
                            if !isLoading {
                                dismiss()
                                newPostContent = ""
                                pastedImage = nil
                            }
                        }
                        .foregroundColor(.gray)
                        .disabled(isLoading)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Post") {
                            createPost()
                        }
                        .disabled(isPostButtonDisabled || isLoading)
                        .font(.headline)
                        .foregroundColor((isPostButtonDisabled || isLoading) ? .gray : .primary)
                    }
                }
                .alert("Inappropriate Content", isPresented: $showProfanityAlert) {
                    Button("OK", role: .cancel) {
                        lastCheckedContent = newPostContent
                    }
                } message: {
                    Text("Your post contains inappropriate language. Please revise your content to maintain a respectful community environment.")
                }
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Uploading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
        }
    }
    
    private var isPostButtonDisabled: Bool {
        newPostContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && pastedImage == nil ||
        newPostContent.count > maxCharacterCount
    }
    
    private func createPost() {
        guard let currentUser = authManager.currentUser else {
            showError = true
            errorMessage = "You must be logged in to create a post"
            return
        }
        let content = newPostContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if content.isEmpty && pastedImage == nil { return }
        if content.count > maxCharacterCount { return }
        if content != lastCheckedContent {
            if ContentFilteringService.shared.containsProfanity(content) {
                showProfanityAlert = true
                return
            }
            lastCheckedContent = content
        }
        isLoading = true
        Task {
            do {
                try await postRepository.createPost(
                    content: content,
                    authorId: currentUser.id ?? "",
                    authorName: "\(currentUser.firstName) \(currentUser.lastName)",
                    image: pastedImage
                )
                isLoading = false
                didCreatePost?(true)
                dismiss()
            } catch {
                isLoading = false
                showError = true
                errorMessage = error.localizedDescription
                didCreatePost?(false)
            }
        }
    }
}

// Helper views
struct UserHeaderView: View {
    let user: User
    
    var body: some View {
        HStack {
            if let profileImageURL = user.profileImageURL,
               let url = URL(string: profileImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        ProgressView()
                    }
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

struct PasteablePostEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var pastedImage: UIImage?
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
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .sentences
        textView.isScrollEnabled = true
        textView.keyboardDismissMode = .interactive
        textView.pasteDelegate = context.coordinator
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
    
    class Coordinator: NSObject, UITextViewDelegate, UITextPasteDelegate {
        var parent: PasteablePostEditor
        
        init(_ parent: PasteablePostEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if parent.text.isEmpty {
                textView.text = ""
                textView.textColor = .label
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if parent.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
        }
        
        // MARK: - Image Paste
        func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting, transform item: UITextPasteItem) {
            // First try to load as image
            item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.parent.pastedImage = image
                    }
                } else {
                    // If not an image, try to load as text
                    item.itemProvider.loadObject(ofClass: String.self) { [weak self] (object, error) in
                        if let text = object as? String {
                            DispatchQueue.main.async {
                                if let textView = textPasteConfigurationSupporting as? UITextView {
                                    let currentText = textView.text ?? ""
                                    let selectedRange = textView.selectedRange
                                    let nsText = currentText as NSString
                                    let newText = nsText.replacingCharacters(in: selectedRange, with: text)
                                    textView.text = newText
                                    self?.parent.text = newText
                                }
                            }
                        }
                    }
                }
            }
        }
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