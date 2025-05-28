import SwiftUI

struct EditPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editedContent: String
    let originalPost: Post
    let onSave: (String) -> Void
    @State private var showProfanityAlert = false
    @State private var lastCheckedContent = ""
    private let maxCharacterCount = 500

    init(post: Post, onSave: @escaping (String) -> Void) {
        self.originalPost = post
        self.onSave = onSave
        _editedContent = State(initialValue: post.content)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Edit your post")
                    .font(.headline)
                TextEditor(text: $editedContent)
                    .frame(minHeight: 120, maxHeight: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1.2)
                    )
                    .padding(.bottom, 8)
                HStack {
                    Spacer()
                    Text("\(editedContent.count)/\(maxCharacterCount)")
                        .font(.caption)
                        .foregroundColor(editedContent.count > maxCharacterCount ? .red : .gray)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if editedContent != lastCheckedContent {
                            if ContentFilteringService.shared.containsProfanity(editedContent) {
                                showProfanityAlert = true
                                return
                            }
                            lastCheckedContent = editedContent
                        }
                        onSave(editedContent.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(editedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editedContent.count > maxCharacterCount)
                }
            }
            .alert("Inappropriate Content", isPresented: $showProfanityAlert) {
                Button("OK", role: .cancel) {
                    lastCheckedContent = editedContent
                }
            } message: {
                Text("Your post contains inappropriate language. Please revise your content to maintain a respectful community environment.")
            }
        }
    }
} 