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
    @State private var selectedImages: [UIImage] = []
    @State private var showProfanityAlert = false
    @State private var lastCheckedContent = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false
    var didCreatePost: ((Bool) -> Void)?
    
    private let maxCharacterCount = 1000
    private let maxImages = 4
    
    private var detectedLinks: [URL] {
        newPostContent.detectURLs().map { $0.url }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let user = authManager.currentUser {
                    UserHeaderView(user: user)
                }
                // Text Editor
                TextEditor(text: $newPostContent)
                    .frame(maxHeight: .infinity)
                    .padding()
                    .onChange(of: newPostContent) { newValue in
                        if newValue != lastCheckedContent {
                            lastCheckedContent = newValue
                            checkForProfanity(newValue)
                        }
                    }
                if !newPostContent.isEmpty {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                        Text("Your post will be visible to all fraternity members")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
                
                // Image Grid
                if !selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [GridItem(.fixed(100))], spacing: 8) {
                            ForEach(0..<selectedImages.count, id: \.self) { index in
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        Button(action: {
                                            selectedImages.remove(at: index)
                                            selectedItems.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                        .padding(4),
                                        alignment: .topTrailing
                                    )
                            }
                            
                            if selectedImages.count < maxImages {
                                PhotosPicker(selection: $selectedItems,
                                           maxSelectionCount: maxImages - selectedImages.count,
                                           matching: .images) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .font(.title)
                                                .foregroundColor(.gray)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 120)
                    .padding(.vertical, 8)
                } else {
                    // Add Images Button
                    PhotosPicker(selection: $selectedItems,
                               maxSelectionCount: maxImages,
                               matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Add Photos")
                        }
                        .foregroundColor(.blue)
                        .padding()
                    }
                }
                
                Divider()
                
                // Bottom Bar
                HStack {
                    Text("\(newPostContent.count)/\(maxCharacterCount)")
                        .foregroundColor(newPostContent.count > maxCharacterCount ? .red : .gray)
                    
                    Spacer()
                    
                    Button("Post") {
                        createPost()
                    }
                    .disabled(newPostContent.isEmpty || isLoading || newPostContent.count > maxCharacterCount)
                }
                .padding()
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItems) { items in
                Task {
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                selectedImages.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func createPost() {
        guard let currentUser = authManager.currentUser else { return }
        
        isLoading = true
        Task {
            do {
                try await postRepository.createPost(
                    content: newPostContent,
                    authorId: currentUser.id ?? "",
                    authorName: "\(currentUser.firstName) \(currentUser.lastName)",
                    images: selectedImages
                )
                
                await MainActor.run {
                    didCreatePost?(true)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
            isLoading = false
        }
    }
    
    private func checkForProfanity(_ text: String) {
        // Implement profanity check if needed
    }
}

// Helper views
struct UserHeaderView: View {
    let user: User
    
    var body: some View {
        HStack {
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