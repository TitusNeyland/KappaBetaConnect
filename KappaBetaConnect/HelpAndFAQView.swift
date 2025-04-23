import SwiftUI

struct FAQSection: Identifiable {
    let id = UUID()
    let title: String
    let questions: [FAQItem]
}

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct HelpAndFAQView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedItems: Set<UUID> = []
    
    let sections = [
        FAQSection(title: "ACCOUNT & SETTINGS", questions: [
            FAQItem(question: "How do I update my profile information?", 
                   answer: "Navigate to your profile by tapping the profile tab. Tap 'Manage Profile' to update your personal information, including your name, location, career details, and interests."),
            FAQItem(question: "How do I set my social media links?",
                   answer: "In your profile settings, scroll to the 'Connect With Me' section. You can add links to your LinkedIn, Instagram, and other social platforms."),
            FAQItem(question: "How do I add or change my profile picture?",
                   answer: "Tap your profile picture or the camera icon on your profile page. You can choose one from your gallery.")
        ]),
        
        FAQSection(title: "POSTS & INTERACTIONS", questions: [
            FAQItem(question: "How do I create a new post?", 
                   answer: "Tap the '+' button at the bottom of the Feed tab. You can write your post, add links. Posts are limited to 500 characters."),
            FAQItem(question: "How do I comment on posts?",
                   answer: "Tap the comment icon below any post to view and add comments. Type your comment in the text field and tap 'Post' to submit."),
            FAQItem(question: "How do I like or save posts?", 
                   answer: "Tap the heart icon to like a post.")
        ]),
        
        FAQSection(title: "EVENTS", questions: [
            FAQItem(question: "How do I find upcoming events?", 
                   answer: "Events are displayed on the Home screen and in the Events tab. You can view all upcoming events and filter them by date or type."),
            FAQItem(question: "How do I RSVP to an event?", 
                   answer: "Open an event and tap the 'RSVP' button."),
            FAQItem(question: "How do I add an event to my calendar?", 
                   answer: "When viewing an event, tap the calendar icon to add it to your device's calendar. You can choose which calendar to add it to.")
        ]),
        
        FAQSection(title: "DIRECTORY", questions: [
            FAQItem(question: "How do I search the member directory?", 
                   answer: "In the Directory tab, use the search bar to find members by name. You can also use filters to search by location, industry, or graduation year."),
            FAQItem(question: "How do I filter the directory?", 
                   answer: "Tap the filter icon in the Directory tab to access filtering options. You can filter by location, industry, line number, initiation year, and more."),
        ]),
        
        FAQSection(title: "DONATIONS", questions: [
            FAQItem(question: "How do I make a donation?", 
                   answer: "Tap the QR code icon in the top right of the Home screen to access our Cash App donation link ($kappabeta)."),
            FAQItem(question: "Are donations tax-deductible?", 
                   answer: "Please consult with your tax advisor regarding the deductibility of your donations.")
        ])
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 16) {
                            Text(section.title)
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 2) {
                                ForEach(section.questions) { item in
                                    DisclosureGroup(
                                        isExpanded: Binding(
                                            get: { expandedItems.contains(item.id) },
                                            set: { isExpanded in
                                                if isExpanded {
                                                    expandedItems.insert(item.id)
                                                } else {
                                                    expandedItems.remove(item.id)
                                                }
                                            }
                                        )
                                    ) {
                                        Text(item.answer)
                                            .font(.body)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 20)
                                            .foregroundColor(.gray)
                                    } label: {
                                        Text(item.question)
                                            .font(.body)
                                            .padding(.vertical, 12)
                                    }
                                    .accentColor(.primary)
                                    .padding(.horizontal, 20)
                                    
                                    if item.id != section.questions.last?.id {
                                        Divider()
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color(.secondarySystemBackground))
            .navigationTitle("Help & FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
}

#Preview {
    HelpAndFAQView()
} 
