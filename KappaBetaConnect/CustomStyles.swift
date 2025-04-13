import SwiftUI

struct CustomTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .frame(minHeight: 55)
            .font(.system(size: 18))
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

extension View {
    func customTextField() -> some View {
        self.modifier(CustomTextFieldStyle())
    }
} 