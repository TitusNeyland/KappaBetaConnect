import SwiftUI

// MARK: - Custom Text Field
struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var isSecure: Bool = false
    var allowWhitespace: Bool = true
    var autoCapitalizeFirstLetter: Bool = false
    var autoCapitalizeWords: Bool = false
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.textContentType = textContentType
        textField.isSecureTextEntry = isSecure
        textField.font = .systemFont(ofSize: 16)
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.autocorrectionType = .no
        textField.autocapitalizationType = autoCapitalizeWords ? .words : .none
        
        // Configure the input accessory view to be empty
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField
        
        init(_ parent: CustomTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            if let currentText = textField.text {
                if parent.autoCapitalizeFirstLetter && !currentText.isEmpty {
                    if parent.autoCapitalizeWords {
                        // Capitalize first letter of each word
                        let words = currentText.components(separatedBy: " ")
                        let capitalizedWords = words.map { word in
                            guard !word.isEmpty else { return word }
                            return word.prefix(1).uppercased() + word.dropFirst()
                        }
                        textField.text = capitalizedWords.joined(separator: " ")
                    } else {
                        // Only capitalize first letter
                        let firstLetter = currentText.prefix(1).uppercased()
                        let restOfString = currentText.dropFirst()
                        textField.text = firstLetter + restOfString
                    }
                }
            }
            parent.text = textField.text ?? ""
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if !parent.allowWhitespace {
                // Prevent whitespace characters
                if string.contains(" ") {
                    return false
                }
            }
            return true
        }
    }
}

// MARK: - Custom Text Editor
struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
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
        textView.autocapitalizationType = .none
        
        // Configure the input accessory view to be empty
        textView.inputAssistantItem.leadingBarButtonGroups = []
        textView.inputAssistantItem.trailingBarButtonGroups = []
        
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
        var parent: CustomTextEditor
        
        init(_ parent: CustomTextEditor) {
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

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: 44)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

// MARK: - Custom Text Editor Style
struct CustomTextEditorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: 100)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

// MARK: - View Extensions
extension View {
    func customTextField() -> some View {
        self.modifier(CustomTextFieldStyle())
    }
    
    func customTextEditor() -> some View {
        self.modifier(CustomTextEditorStyle())
    }
}

// MARK: - SwiftUI TextField Extension
extension TextField {
    func customTextField() -> some View {
        self
            .textFieldStyle(.plain)
            .frame(height: 44)
            .font(.system(size: 16))
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
    }
} 